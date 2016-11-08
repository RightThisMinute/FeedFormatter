
import Axis
import File
import Foundation
import HTTPClient
import HTTPServer
import Mapper
import MuttonChop


let cli = CLI()
let logAppender = LogAppender("Main", levels: [.all])
let log = Logger(name: "Main", appenders: [logAppender])
let config: Config

do {
	config = try Config(path: cli.configPath)
	debugPrint(config)
	
} catch {
	debugPrint("danger danger", error)
	exit(EXIT_FAILURE)
}

let router = BasicRouter { route in
	route.get("/feeds/:id") { request in
		guard let id = request.pathParameters["id"] else {
			return Response(status: .unprocessableEntity,
			                body: "Feed ID missing.")
  	}
		
		guard let feedConfig = config.feeds.filter({ $0.id == id }).first else {
			return Response(status: .notFound,
			                body: "No feed with ID \(id) found.")
		}
		
		guard let url = feedConfig.providerURL else {
			return Response(status: .internalServerError,
			                body: "Failed generating provider URL.")
		}
		
		let client = try Client(url: url)
		var response = try client.get(url.absoluteString,
		                              middleware: [LogMiddleware()])
		
		guard response.statusCode == 200 else {
			log.error("Unexpected response \(response.status) from provider \(feedConfig.provider) with URL \(url.absoluteString).")
			log.debug(feedConfig)
			log.debug(response)
			
			return Response(status: .badGateway,
			                body: "Failed retreiving data from provider.")
		}
		
		let feed: JWFeed
		
		do {
  		let body = try response.body.becomeBuffer(deadline: 30.seconds)
			
  		guard let map = try JSONMapParser().parse(body) else {
  			return Response(status: .badGateway,
  			                body: "Unexpected data structure from provider.")
  		}
  		
  		feed = try JWFeed(mapper: InMapper(of: map))
		}
		
		let template: Template
		
		do {
  		let name = feedConfig.template ?? config.feedDefaults.template
  		let file = try File(path: config.templatesDir + "/" + name)
  		let buffer = try file.readAll(deadline: 30.seconds)
			file.close()
			
			guard let string = String(bytes: buffer.bytes, encoding: .utf8) else {
				log.error("Template \(file) could not be converted to string.")
				return Response(status: .internalServerError,
				                body: "Failed loading template.")
			}
			
			template = try Template(string)
		}
		
		let playlist: [MuttonChop.Context] = feed.playlist.map { item in
			let source = item.sources
				.filter({ $0.type == "video/mp4" })
				.sorted(by: { ($0.width ?? 0) > ($1.width ?? 0) })
				.first
			
			let pubdate = item.pubdate.asString(
				with: "yyyy-MM-dd'T'HH:mm:ssX"
			)
			
			let custom: [String: Map] = item.custom.map{ (key, value) in
				return (key, .string(value))
			}
			
			return [
				"mediaID":     .string(item.mediaID),
				"title":       .string(item.title),
				"description": .string(item.description ?? ""),
				"pubdate":     .string(pubdate),
				"source": [
					"url":      .string(source?.file.absoluteString ?? ""),
					"type":     .string(source?.type ?? ""),
					"duration": .int(Int(source?.duration ?? 0)),
				],
				"thumbnail": .string(item.image.absoluteString),
				"link":      .string(item.link.absoluteString),
				"custom":    .dictionary(custom),
			]
		}
		
		let context: MuttonChop.Context = [
			"title": .string(feedConfig.title),
			"playlist": .array(playlist)
		]
		
		let body = template.render(with: context)
		let headers: Headers = [
			"Content-Type": "application/rss+xml; charset=utf-8"
		]
		
		return Response(headers: headers, body: body)
	}
}

let server = try Server(port: Int(config.server.port),
                        middleware: [LogMiddleware()], responder: router)
try server.start()
