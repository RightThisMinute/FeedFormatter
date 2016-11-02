//
//  Yaml.swift
//  MRSSFormatter
//
//  Created by Donovan Mueller on 11/2/16.
//
//

import Mapper
import Yaml

public typealias YAML = Yaml

extension YAML : InMap {
	
	public func get(at indexPath: IndexPathValue) -> YAML? {
		switch (indexPath, self) {
			
		case (.key(let key), .dictionary(let dict)):
			return dict[YAML.string(key)]
			
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
			
		default:
			return nil
		}
	}
	
	public func asArray() -> [YAML]? {
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
