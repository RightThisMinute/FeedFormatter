//
//  Config.swift
//  MRSSFormatter
//
//  Created by Donovan Mueller on 11/2/16.
//
//

import File
import Mapper
import Yaml


struct Config {
	let server: ServerConfig
	let feeds: [FeedConfig]
	
	enum Error : Swift.Error {
		case unexpectedEncoding(String)
	}
}


extension Config : InMappable {
	enum MappingKeys : String, Mapper.IndexPathElement {
		case server, feeds
	}
	
	init<Source : InMap>(mapper: InMapper<Source, MappingKeys>) throws {
		server = try mapper.map(from: .server)
		feeds  = try mapper.map(from: .feeds)
	}

	init(path: String) throws {
		let file = try File(path: path)
		let data = try file.readAll(deadline: 30.seconds)
		file.close()
		
		guard let rawYAML = String(bytes: data.bytes, encoding: .utf8) else {
			throw Config.Error.unexpectedEncoding("Config file not UTF8 encoded.")
		}
		
		let yaml = try YAML.load(rawYAML)
		
		try self.init(mapper: InMapper(of: yaml))
	}
}


struct ServerConfig {
	let port: UInt
}

extension ServerConfig : InMappable {
	enum MappingKeys : String, Mapper.IndexPathElement {
		case port
	}
	
	init<Source : InMap>(mapper: InMapper<Source, MappingKeys>) throws {
		port = UInt(try mapper.map(from: .port) as Int)
	}
}


struct FeedConfig {
	let id: String
	let title: String
	let provider: Provider
	let providerID: String
	let template: String
}

enum Provider : String {
	case JW = "jw"
}

extension FeedConfig : InMappable {
	enum MappingKeys : String, Mapper.IndexPathElement {
		case id, title, provider, provider_id, template_path
	}
	
	init<Source : InMap>(mapper: InMapper<Source, MappingKeys>) throws {
		id = try mapper.map(from: .id)
		title = try mapper.map(from: .title)
		provider = try mapper.map(from: .provider)
		providerID = try mapper.map(from: .provider_id)
		template = (try? mapper.map(from: .template_path)) ?? "default"
	}
}
