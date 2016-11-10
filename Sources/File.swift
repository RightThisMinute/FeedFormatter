//
//  File.swift
//  MRSSFormatter
//
//  Created by Donovan Mueller on 11/4/16.
//
//

import File
import Foundation

extension File {
	
	/// Resolves the absolute path of the passed path.
	///
	/// Supported shortcuts: ~, ., ..
	///
	/// - parameters:
	///		+ path: A file system path (can be absolute).
	///		+ relativeTo: The base used if `path` is relative. A common value is
	///		  `File.workingDirectory()`.
	/// - returns:
	///		The absolute file system path.
	
	public static func resolve(path: String, relativeTo: String? = nil)
		-> String
	{
		let relativeTo = relativeTo ?? File.workingDirectory
		
		if (path.characters.count == 0 || [".", "./"].contains(path)) {
			return relativeTo
		}
		
		var resolved = path
		if resolved.hasSuffix("/") {
			let allButLastCharacter =
				resolved.startIndex..<(resolved.index(before: resolved.endIndex))
			resolved = resolved.substring(with: allButLastCharacter)
		}
		
		if resolved.hasPrefix("/") {
			return resolved
		}
		
		if resolved.hasPrefix("~") {
			let firstCharacter =
				resolved.startIndex..<resolved.index(after: resolved.startIndex)
			return resolved.replacingCharacters(in: firstCharacter,
			                                    with: NSHomeDirectory())
		}
		
		if resolved.hasPrefix("./") {
			let allButFirstTwoCharacters =
				resolved.index(resolved.startIndex, offsetBy: 2)..<resolved.endIndex
			resolved = resolved.substring(with: allButFirstTwoCharacters)
		}
		
		let slash = relativeTo == "/" ? "" : "/"
		resolved = relativeTo + slash + resolved
		
		var pieces = resolved.split(separator: "/").filter{ $0 != "." }
		while pieces.contains("..") {
			let index = pieces.index(of: "..")! // .contains() confirmed it exists.
			pieces.remove(at: index)
			if index > 0 {
				pieces.remove(at: index.advanced(by: -1))
			}
		}
		
		return "/" + pieces.joined(separator: "/")
	}
	
	
	/// Returns the parent directory path of the passed path or root path if the
	/// passed is effectively root.
	
	public static func parent(of child: String) -> String {
		let child = File.resolve(path: child)
		let parts = child.split(separator: "/")
		
		if case 0...1 = parts.count {
			return "/"
		}
		
		return "/" + parts.removedLast().joined(separator: "/")
	}
	
}
