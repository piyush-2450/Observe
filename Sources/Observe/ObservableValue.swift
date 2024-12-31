//
//  ObservableValue.swift
//  Observe
//
//  Created by Piyush Banerjee on 06-Mar-2022.
//  Copyright © 2022 Piyush Banerjee. All rights reserved.
//

import Collections
import Foundation

internal nonisolated(unsafe) var obQueue: DispatchQueue = .init(
	label: "in.rebyld.Observe",
	qos: .default,
	attributes: .concurrent
)

public class ObservableValue<T>: @unchecked Sendable {
	// MARK: - Private scope

	fileprivate typealias OBList = LinkedList<Observer>
	fileprivate typealias OBNode = OBList.Node

	private var observers: OBList = .init()

	// MARK: - Internal scope

	final class UncheckedSendableClosure: @unchecked Sendable {
		let closure: () -> Void

		deinit {
			//
		}

		init(_ closure: @escaping () -> Void) {
			self.closure = closure
		}
	}

	func removeObserver(
		_ ref: ObserverRef,
		_ completion: (@Sendable (ObserverCount) -> Void)? = nil
	) {
		obQueue.async(flags: .barrier) { [weak self] in
			guard let self,
				  let node = ref.node else {
				return
			}
			observers.remove(node)
			completion?(observers.count)
		}
	}

	func asyncAfter(
		timeInterval: TimeInterval,
		execute: @escaping () -> Void
	) {
		let wrapped: UncheckedSendableClosure = .init(execute)

		obQueue
			.asyncAfter(
				deadline: .now() + timeInterval,
				flags: .barrier
			) {
				wrapped.closure()
			}
	}

	deinit {
		//
	}

	// MARK: - ObserverRef

	public struct ObserverRef: @unchecked Sendable {
		fileprivate weak var node: OBNode?

		fileprivate init(_ node: OBNode) {
			self.node = node
		}
	}

	public typealias Observer = (T) -> Void
	public typealias ObserverCount = UInt

	public static func queue() -> DispatchQueue {
		obQueue
	}

	public static func queue(_ queue: DispatchQueue) {
		let oldQueue: DispatchQueue = obQueue

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
				guard let self else {
					return
				}
				observers.forEach { $0(self.value) }
			}
		}
	}

	public var observerCount: ObserverCount {
		obQueue.sync(flags: .barrier) {
			observers.count
		}
	}

	public init(_ value: T) {
		self.value = value
	}

	@discardableResult
	public func observe(_ observer: @escaping Observer) -> ObserverRef {
		obQueue.sync(flags: .barrier) {
			ObserverRef(observers.append(observer))
		}
	}

	public func removeObserver(_ ref: ObserverRef) {
		obQueue.async(flags: .barrier) { [weak self] in
			guard let self,
				  let node = ref.node else {
				return
			}
			observers.remove(node)
		}
	}

	public func removeAllObservers() {
		obQueue.async(flags: .barrier) { [weak self] in
			self?.observers = LinkedList<Observer>()
		}
	}

	// swiftlint:disable explicit_type_interface
	public func wait(timeout: TimeInterval = 5) async throws -> T where T: Sendable {
		try await withCheckedThrowingContinuation { continuation in
			let start = Date()
			var isResumed = false

			let ref = self.observe { result in
				guard isResumed == false else {
					return
				}
				isResumed = true

				self.removeObserver(ref)
				continuation.resume(returning: result)
			}

			asyncAfter(timeInterval: timeout) {
				guard isResumed == false else {
					return
				}
				isResumed = true

				if Date().timeIntervalSince(start) >= timeout {
					self.removeObserver(ref)
					continuation.resume(
						throwing: NSError(
							domain: "TimeoutError",
							code: 1,
							userInfo: nil
						)
					)
				}
			}
		}
	}
	// swiftlint:enable explicit_type_interface
}
