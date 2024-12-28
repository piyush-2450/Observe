//
//  ObservableGrid.swift
//  Observe
//
//  Created by Piyush Banerjee on 06-Mar-2022.
//  Copyright © 2022 Piyush Banerjee. All rights reserved.
//

import Collections
import Foundation

open class ObservableGrid<T>: Grid<ObservableValue<T?>>,
							  @unchecked Sendable {
	// MARK: Internal scope

	deinit {
		//
	}

	// MARK: Public scope

	public subscript(indices: LinearIndex...) -> T? {
		get {
			obQueue.sync(flags: .barrier) {
				super[indices]?.value
			}
		}

		set {
			obQueue.sync(flags: .barrier) {
				if let newValue {
					if let item = super[indices] {
						item.value = newValue
					} else {
						super[indices] = .init(newValue)
					}
				} else {
					super[indices]?.value = nil
				}
			}
		}
	}

	@discardableResult
	public func observe(
		_ indices: LinearIndex...,
		observer: @escaping ObservableValue<T?>.Observer
	) -> ObservableValue<T?>.ObserverRef? {
		let item: ObservableValue<T?>? = obQueue.sync(flags: .barrier) {
			super[indices]
		}

		switch item {
		case .some(let item):
			return item.observe(observer)

		case .none:
			let item: ObservableValue<T?> = .init(nil)
			obQueue.sync(flags: .barrier) {
				super[indices] = item
			}
			return item
				.observe(observer)
		}
	}

	public func removeObserver(
		_ indices: LinearIndex...,
		ref: ObservableValue<T?>.ObserverRef?
	) {
		obQueue.sync(flags: .barrier) {
			if let ref {
				super[indices]?
					.removeObserver(ref) { observerCount in
						if observerCount == 0 {
							super[indices] = nil
						}
					}
			}
		}
	}

	public func removeAllObservers(_ indices: LinearIndex...) {
		obQueue.sync(flags: .barrier) {
			super[indices]?
				.removeAllObservers()
		}
	}

	public func removeAllObservers() {
		obQueue.sync(flags: .barrier) {
			super.forEach { $1?.removeAllObservers() }
		}
	}
}
