//
// Created by Donovan Mueller on 2/22/17.
//

import Foundation



final class Cache<Payload> {
	private typealias CacheBox = (expires: Date, payload: Payload)

	private let maxAge: Double
	private var boxes = [String: CacheBox]()

	init(maxAge: Double) {
		self.maxAge = maxAge
	}

	func get(_ key: String) -> Payload? {
		let now = Date()

		guard let box = boxes[key], box.expires > now else {
			return nil
		}

		return box.payload
	}

	func set(_ key: String, to payload: Payload) {
		boxes[key] = (expires: Date() + maxAge, payload: payload)
	}
}
