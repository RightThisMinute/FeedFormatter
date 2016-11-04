//
//  Array.swift
//  MRSSFormatter
//
//  Created by Donovan Mueller on 11/3/16.
//
//

extension Array {
	
	/// Immutable version of `Array.removeLast()`

	public func removedLast() -> Array<Iterator.Element> {
		var copy = self
		copy.removeLast()
		return copy
	}
	
}
