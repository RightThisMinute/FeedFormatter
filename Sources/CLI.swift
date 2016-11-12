//
//  CLI.swift
//  MRSSFormatter
//
//  Created by Donovan Mueller on 11/2/16.
//
//

import CommandLineKit
import Foundation

struct CLI {
	fileprivate let parser: CommandLineKit.CommandLine
	
	let configPath: String
	
	
	init() {
		parser = CommandLine()
		
		let configPath = StringOption(shortFlag: "c", longFlag: "config",
		                              required: true,
		                              helpMessage: "Path to config file.")
		
		parser.addOptions(configPath)
		
		do {
  		try parser.parse(strict: true)
			
		} catch {
			parser.printUsage(error)
			exit(EXIT_FAILURE)
		}
		
		self.configPath = configPath.value!
	}
}
