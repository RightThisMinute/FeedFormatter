//
//  Date.swift
//  MRSSFormatter
//
//  Created by Donovan Mueller on 11/6/16.
//
//

import Foundation


public typealias DateFormat = String


extension Date {
	
	/// Shortcut to getting a string version of a date via a format string.
	///
	/// - parameter format: The date format string that would normall be set 
	///   `DateFormatter().dateFormat`.
	///
	/// [Format guide](http://www.unicode.org/reports/tr35/tr35-31/tr35-dates.html#Date_Format_Patterns)
	
	public func asString(with format: DateFormat) -> String {
		let formatter = DateFormatter()
		formatter.dateFormat = format
		
		return formatter.string(from: self)
	}
	
}
