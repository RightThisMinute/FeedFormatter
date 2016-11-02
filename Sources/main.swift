import HTTPServer


let cli = CLI()

do {
	let config = try Config(path: cli.configPath)
	debugPrint(config)
	
} catch {
	debugPrint("danger danger", error)
}

let router = BasicRouter { route in
	route.get("/feeds/:id") { request in
		return Response(body: "Hello, \(request.pathParameters["id"])!")
	}
}

let server = try Server(port: 8080, middleware: [LogMiddleware()],
                        responder: router)
try server.start()
