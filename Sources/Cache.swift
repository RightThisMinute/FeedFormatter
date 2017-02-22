//
// Created by Donovan Mueller on 2/22/17.
//

import Foundation



final class Cache<Payload> {
	private typealias CacheBox = (expires: Date, payload: Payload)

	private let maxAge: Double
	private var boxes = [String: CacheBox]()

	init(maxAge: Double = 30.minutes) {
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
		let now = Date().timeIntervalSince1970

		var expires = now + maxAge
		expires -= expires.truncatingRemainder(dividingBy: maxAge)
		if expires < now {
			expires += maxAge
		}

		boxes[key] = (expires: Date(timeIntervalSince1970: expires),
		              payload: payload)
	}
}
