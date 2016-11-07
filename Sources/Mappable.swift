//
//  Mapper.swift
//  MRSSFormatter
//
//  Created by Donovan Mueller on 11/4/16.
//
//

import Axis
import Foundation
import Mapper


extension Date : BasicInMappable {
	public init<Source : InMap>(mapper: BasicInMapper<Source>) throws {
		let interval: TimeInterval = Double(try mapper.map() as Int)
		self.init(timeIntervalSince1970: interval)
	}
}

extension URL : BasicInMappable {
	public init<Source : InMap>(mapper: BasicInMapper<Source>) throws {
		var string: String = try mapper.map()
		
		if string.hasPrefix("//") {
			string = "https:\(string)"
		}
		
		guard let url = URL(string: string) else {
			throw InMapperError.cannotInitializeFromRawValue(string)
		}
		
		self = url
	}
}


extension Dictionary : BasicInMappable {
	public init<Source : InMap>(mapper: BasicInMapper<Source>) throws {
		let source = mapper.source
		self = source.get() ?? [:]
	}
}


extension UInt : BasicInMappable {
	public init<Source : InMap>(mapper: BasicInMapper<Source>) throws {
		if let int: Int = try? mapper.map() {
			guard int >= 0 else {
				throw InMapperError.cannotInitializeFromRawValue(int)
			}
			
			self.init(int)
			return;
		}
		
		if let double: Double = try? mapper.map() {
			guard double >= 0 && double == floor(double) else {
				throw InMapperError.cannotInitializeFromRawValue(double)
			}
			
			self.init(double)
			return;
		}
		
		if let string: String = try? mapper.map() {
			guard let uint = type(of: self).init(string) else {
				throw InMapperError.cannotInitializeFromRawValue(string)
			}
			
			self.init(uint)
			return;
		}
		
		throw InMapperError.wrongType(type(of: self))
	}
}
