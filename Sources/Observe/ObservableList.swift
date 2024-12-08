//
//  ObservableList.swift
//  Observe
//
//  Created by Piyush Banerjee on 06-Mar-2022.
//  Copyright © 2022 Piyush Banerjee. All rights reserved.
//

import Collections
import Foundation

public final class ObservableList<T>: List<ObservableValue<T?>>,
									  @unchecked Sendable {
	// MARK: Internal scope

	deinit {
		//
	}

	// MARK: Public scope

	public subscript(
		row: Index,
		column: Index
	) -> T? {
		get {
			obQueue.sync(flags: .barrier) {
				super[row, column]?.value
			}
		}

		set {
			obQueue.sync(flags: .barrier) {
				if let newValue {
					if let item = super[row, column] {
						item.value = newValue
					} else {
						super[row, column] = .init(newValue)
					}
				} else {
					super[row, column]?.value = nil
				}
			}
		}
	}

	@discardableResult
	public func observe(
		_ row: Index,
		_ column: Index,
		_ observer: @escaping ObservableValue<T?>.Observer
	) -> ObservableValue<T?>.ObserverRef? {
		let item: ObservableValue<T?>? = obQueue.sync(flags: .barrier) {
			super[row, column]
		}

		switch item {
		case .some(let item):
			return item.observe(observer)

		case .none:
			let item: ObservableValue<T?> = .init(nil)
			obQueue.sync(flags: .barrier) {
				super[row, column] = item
			}
			return item
				.observe(observer)
		}
	}

	public func removeObserver(
		_ row: Index,
		_ column: Index,
		_ ref: ObservableValue<T?>.ObserverRef?
	) {
		obQueue.sync(flags: .barrier) {
			if let ref {
				super[row, column]?
					.removeObserver(ref) { observerCount in
						if observerCount == 0 {
							super[row, column] = nil
						}
					}
			}
		}
	}

	public func removeAllObservers(
		_ row: Index,
		_ column: Index
	) {
		obQueue.sync(flags: .barrier) {
			super[row, column]?
				.removeAllObservers()
		}
	}

	public func removeAllObservers() {
		obQueue.sync(flags: .barrier) {
			super.forEach { $2?.removeAllObservers() }
		}
	}
}
