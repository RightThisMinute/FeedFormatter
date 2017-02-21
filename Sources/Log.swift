//
//  Log.swift
//  MRSSFormatter
//
//  Created by Donovan Mueller on 11/3/16.
//
//

import Axis
import File
import Foundation

public struct LogAppender : Appender {
	public let name: String
	public let levels: Logger.Level
	private let file: File?
	
	init(_ name: String, levels: Logger.Level, file: File? = nil) {
		self.name   = name
		self.levels = levels
		self.file   = file
	}
	
	public func append(event: Logger.Event) {
		guard levels.contains(event.level) else { return; }
		
		var entry = ""
		
		let date = Date(timeIntervalSince1970: Double(event.timestamp) ?? 0)
			.asString(with: "yyyy-MM-dd'T'HH:mm:ss")
		entry += ">>=\(date)=> "
		
		if let message = event.message {
			let badLevels: Logger.Level = [.warning, .error, .fatal]
			let (left, right) = badLevels.contains(event.level)
				? ("|>", "<|") : ("", "")
			
			entry += "\(left) \(message) \(right) "
		}
		
		if let error = event.error {
			entry += "!! \(error) ~@ \(event.locationInfo) !!"
		}

		if let file = self.file {
			do {
				try file.write(entry + "\n", deadline: 60.seconds)
				try file.flush(deadline: 60.seconds)
			} catch {
				print(">>=\(date)> FAILED WRITING TO LOG FILE: \(error)")
				print(">>=LAST MESSAGE> \(entry)")
			}
			return
		}

		print(entry)
	}
}
