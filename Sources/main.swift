
import Axis
import File
import Foundation
import HTTPServer
import Mapper
import MuttonChop
import POSIX
import Signals
import Venice


let cli = CLI()
let log: Logger
let config: Config

let initLogAppender = LogAppender("Init", levels: [.all])
let initLog = Logger(name: "Init", appenders: [initLogAppender])

do {
	initLog.info("Reading config...")
	config = try Config(path: cli.configPath)

	if let lockFilePath = config.lockFilePath {
		initLog.info("Checking for lock file at [\(lockFilePath)].")
		guard !File.fileExists(path: lockFilePath) else {
			initLog.info("...already exists. Quitting.")
			exit(EXIT_SUCCESS)
		}

		initLog.info("...does not exist. Creating.")
		try File(path: lockFilePath, mode: .createWrite).close()
	}

	initLog.debug(config)

	let logFile: File?
	if let path = config.logFilePath {
		logFile = try File(path: path, mode: .appendWrite)
		initLog.info("Logging to [\(path)].")
	} else {
		logFile = nil
	}

	let appender = LogAppender("Main", levels: [.all], file: logFile)
	log = Logger(name: "Main", appenders: [appender])

	log.info("Initialized.")

} catch {
	initLog.error("Failed initializing.", error: error)
	exit(EXIT_FAILURE)
}


func cleanup() {
	guard let lockFilePath = config.lockFilePath else { return; }
	
	log.info("Removing lock file [\(lockFilePath)].")
	do {
		try File.removeFile(path: lockFilePath)
	} catch {
		log.error("Failed removing lock file [\(lockFilePath)]", error: error)
	}
}

defer { cleanup() }

Signals.trap(signals: [.abrt, .alrm, .hup, .int, .kill, .quit, .term]){ sig in
	log.info("Received [\(sig)] signal. Cleaning up.")
	cleanup()
	exit(sig)
}


let responseCache: Cache<Response>?

if let maxAge = config.responseCacheMaxAge {
	responseCache = Cache<Response>(maxAge: maxAge)
} else {
	responseCache = nil
}


let router = BasicRouter { route in

	var counter = 0

	route.get("/feeds/:id") { request in

		counter += 1
		let req = "[\(counter)] "

		let cacheKey = "\(request.method) \(request.url.path)"

		log.debug("Handling request \(req)for [\(cacheKey)]...")
		log.trace(request)

		guard let id = request.pathParameters["id"] else {
			log.debug("\(req)missing feed ID parameter.")
			return Response(status: .unprocessableEntity,
			                body: "Feed ID missing.")
  	}

		guard let feedConfig = config.feeds.filter({ $0.id == id }).first else {
			log.debug("\(req)unknown feed ID.")
			return Response(status: .notFound,
			                body: "No feed with ID \(id) found.")
		}

		guard let url = feedConfig.providerURL else {
			log.debug("\(req)failed generating provider URL.")
			return Response(status: .internalServerError,
			                body: "Failed generating provider URL.")
		}

		if let cache = responseCache {
			let pattern = try Regex("(^|&)fresh=1(&|$)")
			let getFresh =
				request.url.query != nil && request.url.query!.matches(pattern)

			if getFresh {
				log.debug("\(req)fresh version requested, skipping cache.")

			} else {
				log.debug("\(req)looking in cache.")

				if let response = cache.get(cacheKey) {
					log.debug("\(req)delivering cached response.")
					return response
				}

				log.debug("\(req)not found in cache.")
			}
		}

		log.debug("\(req)requesting feed from provider: [GET \(url.absoluteString)]")
		let bodyData: Data

		do {
			var reqData: Data? = nil
			var reqResponse: URLResponse? = nil
			var reqError: Error? = nil

			let session = URLSession(configuration: URLSessionConfiguration.default)
			let task = session.dataTask(with: url) { data, response, error in
				reqData = data
				reqResponse = response
				reqError = error
			}

			task.resume()

			/// The obvious solution would be to send to the channel in the
			/// `URLSessions.shared.dataTask()` response handler, but that causes a
			/// crash in `CLibvenice` that I couldn't figure out how to get around.

			let requestCompleted = Channel<Bool>()
			let timeout = Date() - 30.seconds

			every(50.milliseconds) { done in
				if task.state == .completed {
					requestCompleted.send(true)
					done()
				}

				if task.state == .canceling || Date() >= timeout {
					requestCompleted.send(false)
					done()
				}
			}

			guard let completed = requestCompleted.receive(), completed else {
				log.error("Request [GET \(url.absoluteString)] timed out.")
				return Response(status: .gatewayTimeout,
				                body: "The provider took too long to respond.")
			}

			guard reqError == nil else {
				log.error("Failed making request [GET \(url.absoluteString)].",
				          error: reqError!)
				log.debug(reqResponse)
				return Response(status: .badGateway,
				                body: "Failed retrieving data from provider.")
			}

			guard reqData != nil else {
				log.error("Provider returned no data for request [GET \(url.absoluteString)]")
				log.debug(reqResponse)
				return Response(status: .badGateway,
				                body: "Failed retrieving data from provider.")
			}

			bodyData = reqData!
		}


		let feed: JWFeed

		do {
			guard let body = String(data: bodyData, encoding: .utf8) else {
				log.error("Failed converting provider response to UTF8 string.")
				log.debug(bodyData)
				return Response(status: .badGateway,
				                body: "Unexpected encoding from provider.")
			}

  		guard let map = try JSONMapParser().parse(body.buffer) else {
			  log.error("Unexpected data structure from provider.")
			  log.debug(body)
  			return Response(status: .badGateway,
  			                body: "Unexpected data structure from provider.")
  		}

  		feed = try JWFeed(mapper: InMapper(of: map))
			
		} catch let error as JSONMapParserError {
			log.error("Failed parsing JSON response from provider.",
			          error: error)
			log.debug(String(data: bodyData, encoding: .utf8))

			return Response(status: .internalServerError,
			                body: "The provider gave an unexpected response.")
		}

		let template: Template

		do {
			log.debug("\(req)loading template.")

  		let name = feedConfig.template ?? config.feedDefaults.template
  		let file = try File(path: config.templatesDir + "/" + name)
  		let buffer = try file.readAll(deadline: 30.seconds)
			file.close()

			log.trace("\(req)template name: \(name)")

			guard let string = String(bytes: buffer.bytes, encoding: .utf8) else {
				log.error("Template \(name) could not be converted to string.")
				return Response(status: .internalServerError,
				                body: "Failed loading template.")
			}

			template = try Template(string)
			
		} catch {
			log.error("Failed reading and parsing template.", error: error)
			log.debug(feedConfig)
			
			return Response(status: .internalServerError,
			                body: "Failed parsing feed template.")
		}

		log.debug("\(req)building template context.")

		let playlist: [MuttonChop.Context] = feed.playlist.map { item in

			let pubdate = item.pubdate.asString(
				/// [ISO 8601](https://www.w3.org/TR/NOTE-datetime) compatible
				/// for easier parsing by clients.
				with: "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
			)

			let custom: [String: Map] = item.custom.map{ (key, value) in
				return (key, .string(value))
			}

			let source = item.sources
				.filter({ $0.type == "video/mp4" })
				.sorted(by: { ($0.width ?? 0) > ($1.width ?? 0) })
				.first

			var sourceFile: [String: Map] = [
				"url":      .string(source?.file.absoluteString ?? ""),
				"type":     .string(source?.type ?? ""),
				"duration": .int(Int(source?.duration ?? 0)),
			]

			/// For some reason, putting these two values in the dictionary
			/// literal that initializes `sourceFile` causes compliation to freeze
			/// in Xcode and to take ~225 seconds building via the command line.
			/// Assigning these values afterwards completely avoids the issue.
			///
			/// This was found with Xcode 8.1 and Swift 3.0 release.
			sourceFile["width"]  = .int(Int(source?.width ?? 0))
			sourceFile["height"] = .int(Int(source?.height ?? 0))

			return [
				"mediaID":     .string(item.mediaID),
				"title":       .string(item.title),
				"description": .string(item.description ?? ""),
				"pubdate":     .string(pubdate),
				"source":			 .dictionary(sourceFile),
				"thumbnail":   .string(item.image.absoluteString),
				"link":        .string(item.link.absoluteString),
				"custom":      .dictionary(custom),
			]
		}

		let context: MuttonChop.Context = [
			"title": .string(feedConfig.title),
			"description": .string(feedConfig.description ?? ""),
			"link": .string(feedConfig.link ?? config.feedDefaults.link),
			"playlist": .array(playlist)
		]

		let body = template.render(with: context)
		let headers: Headers = [
			"Content-Type": "application/rss+xml; charset=utf-8"
		]

		log.debug("\(req)responding with rendered template.")
		let response = Response(headers: headers, body: body)

		if let cache = responseCache {
			log.debug("\(req)caching response.")
			cache.set(cacheKey, to: response)
		}
		return response
	}
}

do {
	let server = try Server(port: Int(config.server.port), responder: router)
	try server.start()

} catch {
	log.error("Failed initializaing or starting server.", error: error)
	cleanup()
	exit(EXIT_FAILURE)
}
