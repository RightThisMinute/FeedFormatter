//
//  Config.swift
//  MRSSFormatter
//
//  Created by Donovan Mueller on 11/2/16.
//
//

import Foundation
import File
import Mapper
import MuttonChop
import Yaml
import YAMLMapper


struct Config {
	/// Directory the config lives in.
	let directory: String
	let lockFilePath: String?
	let logFilePath: String?
	let responseCacheMaxAge: Double?
	let server: ServerConfig

	let feeds: [FeedConfig]
	let feedDefaults: FeedConfigDefaults

	let templatesDir: String

	enum Error : Swift.Error {
		case unexpectedEncoding(String)
		case unknownPreprocessor
	}
}


extension Config : InMappable {
	enum MappingKeys : String, Mapper.IndexPathElement {
		case directory, lock_file_path, log_file_path, response_cache_max_age,
		     server, feed_defaults, feeds, templates_dir
	}

	init<Source : InMap>(mapper: InMapper<Source, MappingKeys>) throws {
		directory = try mapper.map(from: .directory)

		if let path: String = try? mapper.map(from: .lock_file_path) {
			lockFilePath = File.resolve(path: path, relativeTo: directory)
		} else {
			lockFilePath = nil
		}

		if let path: String = try? mapper.map(from: .log_file_path) {
			logFilePath = File.resolve(path: path, relativeTo: directory)
		} else {
			logFilePath = nil
		}

		if let maxAge: Int = try? mapper.map(from: .response_cache_max_age) {
			responseCacheMaxAge = maxAge.minutes
		} else {
			responseCacheMaxAge = nil
		}

		server = try mapper.map(from: .server)
		feeds  = try mapper.map(from: .feeds)
		feedDefaults = try mapper.map(from: .feed_defaults)

		let dir: String = try mapper.map(from: .templates_dir)
		templatesDir = File.resolve(path: dir, relativeTo: directory)
	}

	init(path: String) throws {
		let file = try File(path: path)
		let data = try file.readAll(deadline: 30.seconds)
		file.close()

		guard let rawYAML = String(bytes: data.bytes, encoding: .utf8) else {
			throw Config.Error.unexpectedEncoding("Config file not UTF8 encoded.")
		}

		var yaml = try YAML.load(rawYAML)
		yaml["directory"] = YAML.string(File.parent(of: path))

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


struct FeedConfigDefaults {
	let link: String
	let template: String
	let defaultImage: URL?
}

extension FeedConfigDefaults : InMappable {
	enum MappingKeys : String, Mapper.IndexPathElement {
		case link, template, default_image
	}

	init<Source : InMap>(mapper: InMapper<Source, MappingKeys>) throws {
		link = try mapper.map(from: .link)
		template = try mapper.map(from: .template)
		defaultImage = try? mapper.map(from: .default_image)
	}
}


struct FeedConfig {
	let id: String
	let title: String
	let description: String?
	let link: String?

	let provider: Provider
	let providerID: String
	var providerURL: URL? {
		return provider.url(for: providerID)
	}

	let template: String?
	let preprocessor: ((MuttonChop.Context, JWItem) -> MuttonChop.Context)?
}

enum Provider : String {
	case JW = "jw"

	func url(for id: String) -> URL? {
		return URL(string: "https://content.jwplatform.com/feeds/\(id).json")
	}
}

extension FeedConfig : InMappable {
	enum MappingKeys : String, Mapper.IndexPathElement {
		case id, title, description, link, provider, provider_id, template,
		     preprocessor
	}

	init<Source : InMap>(mapper: InMapper<Source, MappingKeys>) throws {
		id = try mapper.map(from: .id)
		title = try mapper.map(from: .title)
		description = try? mapper.map(from: .description)
		link = try? mapper.map(from: .link)
		provider = try mapper.map(from: .provider)
		providerID = try mapper.map(from: .provider_id)
		template = try? mapper.map(from: .template)

		if let name: String = try? mapper.map(from: .preprocessor) {
			switch name {
			case "LightWorkers":
				preprocessor = LightWorkersPreprocessor.process
			case "MailChimp":
				preprocessor = MailChimpPreprocessor.process
			default:
				throw Config.Error.unknownPreprocessor
			}
		} else {
			preprocessor = nil
		}
	}
}
