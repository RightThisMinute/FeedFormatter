
import Axis
import File
import Foundation
import HTTPClient
import HTTPServer
import Mapper
import MuttonChop
import Signals


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


let router = BasicRouter { route in
	route.get("/feeds/:id") { request in

		log.debug("Handling request for [\(request.method) \(request.url.absoluteString)]...")
		log.trace(request)

		guard let id = request.pathParameters["id"] else {
			log.debug("...missing feed ID parameter.")
			return Response(status: .unprocessableEntity,
			                body: "Feed ID missing.")
  	}

		guard let feedConfig = config.feeds.filter({ $0.id == id }).first else {
			log.debug("...unknown feed ID.")
			return Response(status: .notFound,
			                body: "No feed with ID \(id) found.")
		}

		guard let url = feedConfig.providerURL else {
			log.debug("...failed generating provider URL.")
			return Response(status: .internalServerError,
			                body: "Failed generating provider URL.")
		}
		
		var response: Response

		do {
			log.debug("...requesting feed from provider: [GET \(url.absoluteString)]")
			response = try Client(url: url).get(url.absoluteString)
			
		} catch {
			log.error("Failed making request [GET \(url.absoluteString)].",
			          error: error)
			
			return Response(status: .badGateway,
			                body: "Failed retrieving data from provider.")
		}

		guard response.statusCode == 200 else {
			log.error("Unexpected response \(response.status) from provider \(feedConfig.provider) with URL \(url.absoluteString).")
			log.debug(feedConfig)
			log.debug(response)

			return Response(status: .badGateway,
			                body: "Failed retrieving data from provider.")
		}

		let feed: JWFeed

		do {
  		let body = try response.body.becomeBuffer(deadline: 5.seconds)

  		guard let map = try JSONMapParser().parse(body) else {
			  log.error("Unexpected data structure from provider.")
			  log.debug(try String(buffer: body))
  			return Response(status: .badGateway,
  			                body: "Unexpected data structure from provider.")
  		}

  		feed = try JWFeed(mapper: InMapper(of: map))
			
		} catch let error as JSONMapParserError {
			log.error("Failed parsing JSON response from provider.",
			          error: error)
			log.debug(response)

			return Response(status: .internalServerError,
			                body: "The provider gave an unexpected response.")
		}

		let template: Template

		do {
			log.debug("...loading template.")

  		let name = feedConfig.template ?? config.feedDefaults.template
  		let file = try File(path: config.templatesDir + "/" + name)
  		let buffer = try file.readAll(deadline: 30.seconds)
			file.close()

			log.trace("...template name: \(name)")

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

		log.debug("...building template context.")

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

		log.debug("...responding with rendered template.")

		return Response(headers: headers, body: body)
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
