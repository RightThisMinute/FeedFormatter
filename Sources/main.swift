
import Axis
import Foundation
import Mapper
import HTTPServer
import HTTPClient


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
		
		let body = try response.body.becomeBuffer(deadline: 30.seconds)
		
		guard let map = try JSONMapParser().parse(body) else {
			return Response(status: .badGateway,
			                body: "Unexpected data structure from provider.")
		}
		
		let feed = try JWFeed(mapper: InMapper(of: map))
		
		return Response(body: "Hello, \(url)!")
	}
}

let server = try Server(port: 8080, middleware: [LogMiddleware()],
                        responder: router)
try server.start()
