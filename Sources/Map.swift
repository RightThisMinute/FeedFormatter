//
//  JSON.swift
//  MRSSFormatter
//
//  Created by Donovan Mueller on 11/4/16.
//
//

import Axis
import Mapper


extension Map : InMap {
	
	public func get(at indexPath: Mapper.IndexPathValue) -> Map? {
		switch (indexPath, self) {
			
		case (.key(let key), .dictionary(let dict)):
			return dict[key]
			
		case  (.index(let index), .array(let array)):
			if array.indices.contains(index) {
				return array[index]
			}
			return nil
			
		default:
			return nil
		}
	}
	
	public func get<T>() -> T? {
		switch self {
			
		case .bool(let bool as T):
			return bool
			
		case .int(let int as T):
			return int
			
		case .double(let double as T):
			return double
			
		case .string(let string as T):
			return string
			
		case .array(let array as T):
			return array
			
		case .dictionary(let dict as T):
			return dict
			
		case .buffer(let buffer as T):
			return buffer
			
		default:
			return nil
		}
	}
	
	public func asArray() -> [Map]? {
		if case .array(let value) = self {
			return value
		}
		return nil
	}
	
	public var int: Int? {
		if case .int(let value) = self {
			return value
		}
		return nil
	}
	
	public var double: Double? {
		if case .double(let value) = self {
			return value
		}
		return nil
	}
	
	public var bool: Bool? {
		if case .bool(let value) = self {
			return value
		}
		return nil
	}
	
	public var string: String? {
		if case .string(let value) = self {
			return value
		}
		return nil
	}
	
}
