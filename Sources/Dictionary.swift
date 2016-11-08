//
//  Dictionary.swift
//  MRSSFormatter
//
//  Created by Donovan Mueller on 11/8/16.
//
//


extension Dictionary {
	
	/// Create a dictionary from a list of key/value pairs.
	
	public init(_ pairs: [(Key, Value)]) {
		var dict = [Key: Value]()
		
		for (key, value) in pairs {
			dict[key] = value
		}
		
		self = dict
	}
	
	
	/// Apply a transform to a dictionary's values and keys and return a new
	/// dictionary.
	
	public func map<OutKey: Hashable, OutValue>(
		_ transform: @escaping ((key: Key, value: Value)) throws -> (OutKey, OutValue))
		rethrows -> [OutKey: OutValue]
	{
		let pairs: [(OutKey, OutValue)] = try self.map{ pair in
			return try transform(pair)
		}
		
		return Dictionary<OutKey, OutValue>(pairs)
	}

}
