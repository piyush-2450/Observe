//
//  Observe.swift
//  Observe
//
//  Created by Piyush Banerjee on 06-Mar-2022.
//  Copyright © 2022 Piyush Banerjee. All rights reserved.
//

import Foundation
import Collections

private nonisolated(unsafe) var obQueue: DispatchQueue = .init(
	label: "in.rebyld.Observe",
	qos: .default,
	attributes: .concurrent
)

public final class ObservableValue<T>: @unchecked Sendable {
	// MARK: - Private scope

	fileprivate typealias OBList = LinkedList<Observer>
	fileprivate typealias OBNode = OBList.Node

	private var observers: OBList = .init()

	// MARK: - ObserverRef

	public struct ObserverRef: @unchecked Sendable {
		fileprivate weak var node: OBNode?

		fileprivate init(_ node: OBNode) {
			self.node = node
		}
	}

	public typealias Observer = (T) -> Void

	public static func queue() -> DispatchQueue {
		obQueue
	}

	public static func queue(_ queue: DispatchQueue) {
		let oldQueue = obQueue

		oldQueue.async(flags: .barrier) {
			obQueue = queue
		}

		oldQueue.sync(flags: .barrier) {
			queue.sync(flags: .barrier) {
				//
			}
		}
	}

	public var value: T {
		didSet {
			obQueue.async { [weak self] in
				guard let self = self else { return }
				self.observers.forEach { $0(self.value) }
			}
		}
	}

	public init(_ value: T) {
		self.value = value
	}

	@discardableResult
	public func observe(_ observer: @escaping Observer) -> ObserverRef {
		obQueue.sync(flags: .barrier) {
			let node = observers.append(observer)
			return ObserverRef(node)
		}
	}

	public func removeObserver(_ token: ObserverRef) {
		obQueue.async(flags: .barrier) { [weak self] in
			guard let self = self,
				  let node = token.node else { return }
			self.observers.remove(node)
		}
	}

	public func removeAllObservers() {
		obQueue.async(flags: .barrier) { [weak self] in
			self?.observers = LinkedList<Observer>()
		}
	}
}
