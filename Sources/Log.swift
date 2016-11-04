//
//  Log.swift
//  MRSSFormatter
//
//  Created by Donovan Mueller on 11/3/16.
//
//

import Axis
import Foundation

public struct LogAppender : Appender {
	public let name: String
	public let levels: Logger.Level
	
	init(_ name: String, levels: Logger.Level) {
		self.name   = name
		self.levels = levels
	}
	
	public func append(event: Logger.Event) {
		guard levels.contains(event.level) else { return; }
		
		var entry = ""
		
		let formatter = DateFormatter()
		formatter.dateFormat = "HH':'mm':'ss"
		let date = Date(timeIntervalSince1970: Double(event.timestamp) ?? 0)
		
		entry += ">>=\(formatter.string(from: date))=> "
		
		if let message = event.message {
			let badLevels: Logger.Level = [.warning, .error, .fatal]
			let (left, right) = badLevels.contains(event.level)
				? ("|>", "<|") : ("", "")
			
			entry += "\(left) \(message) \(right) "
		}
		
		if let error = event.error {
			entry += "!! \(error) ~@ \(event.locationInfo) !!"
		}
		
		print(entry)
	}
}
