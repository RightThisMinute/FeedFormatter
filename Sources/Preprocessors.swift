//
// Created by Donovan Mueller on 5/18/17.
//

import Foundation
import MuttonChop

struct LightWorkersPreprocessor {
	static func process(context: Context, with item: JWItem) -> Context {
		let pubdate = item.pubdate.asString(with: "M/dd/yyyy")

		let source = context["source"]

		let duration: String

		if let seconds = source["duration"].int {
			let hours     = seconds / (60*60)
			let minutes   = (seconds - hours*60*60) / 60
			let remainder = seconds - hours*60*60 - minutes*60

			duration = String(format: "%d:%02d:%02d", hours, minutes, remainder)
		} else {
			duration = "0:00:00"
		}

		let dimensions: String
		let quality: String

		if let width  = source["width"].int, let height = source["height"].int {
			dimensions = "\(width)x\(height)"

			if height >= 1080 {
				quality = "Full HD"
			} else if height >= 720 {
				quality = "HD"
			} else {
				quality = "SD"
			}
		} else {
			dimensions = "1280x720"
			quality = "HD"
		}

		var context = context
		context["creationDate"] = .string(pubdate)
		context["publishDate"]  = .string(pubdate)
		context["duration"]     = .string(duration)
		context["dimensions"]   = .string(dimensions)
		context["videoQuality"] = .string(quality)

		return context
	}
}

struct MailChimpPreprocessor {
	static func process(context: Context, with item: JWItem) -> Context {
		// Must be RFC 822
		let pubdate = item.pubdate.asString(with: "EEE, dd MMM yyyy HH:mm:ss ZZZ")

		var context = context
		context["pubdate"] = .string(pubdate)
		return context
	}
}
