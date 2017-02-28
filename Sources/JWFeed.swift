//
//  JWFeed.swift
//  MRSSFormatter
//
//  Created by Donovan Mueller on 11/4/16.
//
//

import Axis
import Foundation
import Mapper


struct JWFeed {
	let id: String
	let title: String
	let kind: String
	let playlist: [JWItem]
}

extension JWFeed : InMappable {

	enum MappingKeys : String, Mapper.IndexPathElement {
		case kind, feedid, playlist, title
	}

	init<Source : InMap>(mapper: InMapper<Source, MappingKeys>) throws {
		id = try mapper.map(from: .feedid)
		title = try mapper.map(from: .title)
		kind = try mapper.map(from: .kind)
		playlist = try mapper.map(from: .playlist)
	}
}


struct JWItem {
	let mediaID: String
	let title: String
	let description: String?
	let pubdate: Date
	let sources: [JWSource]
	let duration: UInt
	let image: URL?
	let tracks: [JWTrack]
	let tags: [String]
	let link: URL
	let custom: [String: String]
}

extension JWItem : InMappable {

	enum MappingKeys : String, Mapper.IndexPathElement {
		case mediaid, title, description, pubdate, sources, duration, image,
		     tracks, tags, link, custom
	}

	init<Source : InMap>(mapper: InMapper<Source, MappingKeys>) throws {
		mediaID = try mapper.map(from: .mediaid)
		title = try mapper.map(from: .title)
		description = try? mapper.map(from: .description)
		pubdate = try mapper.map(from: .pubdate)
		sources = try mapper.map(from: .sources)
		duration = UInt(try mapper.map(from: .duration) as Int)
		tracks = try mapper.map(from: .tracks)
		tags = (try mapper.map(from: .tags) as String).split(separator: ",")
		link = try mapper.map(from: .link)

		if let image: URL = try? mapper.map(from: .image) {
			/// Use the largest available version of the thumbnails.
			/// See https://developer.jwplayer.com/jw-platform/reference/v1/urls/thumbs.html
			let pattern     = try Regex("-[0-9]+(\\.jpg)$", options: .extended)
			let bigImageURL = image.absoluteString.replace(pattern, with: ".jpg")
			self.image = try URL(string: bigImageURL) ?? mapper.map(from: .image)

		} else {
			self.image = nil
		}

		if let dict: [String: Map] = try? mapper.unsafe_map(from: .custom) {
			custom = dict.map{ (k, v) in return (k, (try? v.get()) ?? "") }
		} else {
			custom = [String: String]()
		}
	}
}


struct JWSource {
	let label: String?
	let type: String
	let file: URL
	let width: UInt?
	let height: UInt?
	let duration: UInt?
}

extension JWSource : InMappable {

	enum MappingKeys : String, Mapper.IndexPathElement {
		case label, type, file, width, height, duration
	}

	init<Source : InMap>(mapper: InMapper<Source, MappingKeys>) throws {
		label    = try? mapper.map(from: .label)
		type     = try  mapper.map(from: .type)
		file     = try  mapper.map(from: .file)
		width    = try? mapper.map(from: .width)
		height   = try? mapper.map(from: .height)
		duration = try? mapper.map(from: .duration)
	}

}


struct JWTrack {
	let kind: String
	let file: URL
}

extension JWTrack : InMappable {

	enum MappingKeys : String, Mapper.IndexPathElement {
		case kind, file
	}

	init<Source : InMap>(mapper: InMapper<Source, MappingKeys>) throws {
		kind = try mapper.map(from: .kind)
		file = try mapper.map(from: .file)
	}

}
