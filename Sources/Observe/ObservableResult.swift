//
//  ObservableResult.swift
//  Observe
//
//  Created by Piyush Banerjee on 30/12/24.
//

import Foundation

infix operator => : AdditionPrecedence

public final class ObservableResult<
	Success,
	Failure: Error
>: ObservableValue<Result<Success, Failure>?>,
   @unchecked Sendable {
	// MARK: - Private scope

	// MARK: - Internal scope

	deinit {
		// print("Deinit: \(ObjectIdentifier(self))")
	}

	// MARK: - Public scope

	public typealias ResultObserver = (Result<Success, Failure>) -> Void
	public typealias SuccessObserver = (Success) -> Void
	public typealias FailureObserver = (Failure) -> Void

	public typealias ResultTransformer<
		NextSuccess,
		NextFailure: Error
	> = (
		Result<
		Success,
		Failure
		>
	) -> Result<
		NextSuccess,
		NextFailure
	>

	public typealias SuccessTransformer<NextSuccess> = (Success) -> NextSuccess
	public typealias FailureTransformer<NextFailure> = (Failure) -> NextFailure

	// swiftlint:disable modifier_order
	public override init(_ value: Result<Success, Failure>? = nil) {
		super.init(value)
	}
	// swiftlint:enable modifier_order

	@discardableResult
	public func result(_ observer: @escaping ResultObserver) -> ObserverRef {
		observe { result in
			guard let result else {
				return
			}

			observer(result)
		}
	}

	@discardableResult
	public func success(_ observer: @escaping SuccessObserver) -> ObserverRef {
		observe { result in
			guard let result else {
				return
			}

			switch result {
			case .success(let value):
				observer(value)

			case .failure:
				break
			}
		}
	}

	@discardableResult
	public func failure(_ observer: @escaping FailureObserver) -> ObserverRef {
		observe { result in
			guard let result else {
				return
			}

			switch result {
			case .success:
				break

			case .failure(let error):
				observer(error)
			}
		}
	}

	// swiftlint:disable explicit_type_interface
	public func next<
		NextSuccess,
		NextFailure: Error
	>(
		_ transformer: @escaping ResultTransformer<NextSuccess, NextFailure>
	) -> ObservableResult<NextSuccess, NextFailure> {
		let nextResult = ObservableResult<NextSuccess, NextFailure>()

		self.observe { result in
			guard let result else {
				return
			}

			let transformedResult = transformer(result)
			nextResult.value = transformedResult
		}

		return nextResult
	}

	public func next<NextSuccess>(
		_ transformer: @escaping SuccessTransformer<NextSuccess>
	) -> ObservableResult<NextSuccess, Failure> {
		let nextResult = ObservableResult<NextSuccess, Failure>()

		self.observe { result in
			guard let result else {
				return
			}

			switch result {
			case .success(let value):
				let newValue = transformer(value)
				nextResult.value = .success(newValue)

			case .failure(let error):
				nextResult.value = .failure(error)
			}
		}

		return nextResult
	}

	public func next<NextFailure>(
		_ transformer: @escaping FailureTransformer<NextFailure>
	) -> ObservableResult<Success, NextFailure> {
		let nextResult = ObservableResult<Success, NextFailure>()

		self.observe { result in
			guard let result else {
				return
			}

			switch result {
			case .success(let value):
				nextResult.value = .success(value)

			case .failure(let error):
				let newError = transformer(error)
				nextResult.value = .failure(newError)
			}
		}

		return nextResult
	}
	// swiftlint:enable explicit_type_interface

	@discardableResult
	public static func => <
		NextSuccess,
		NextFailure: Error
	>(
		current: ObservableResult<Success, Failure>,
		transformer: @escaping ResultTransformer<NextSuccess, NextFailure>
	) -> ObservableResult<NextSuccess, NextFailure> {
		current.next(transformer)
	}

	@discardableResult
	public static func => <NextSuccess>(
		current: ObservableResult<Success, Failure>,
		transformer: @escaping SuccessTransformer<NextSuccess>
	) -> ObservableResult<NextSuccess, Failure> {
		current.next(transformer)
	}

	@discardableResult
	public static func => <NextFailure>(
		current: ObservableResult<Success, Failure>,
		transformer: @escaping FailureTransformer<NextFailure>
	) -> ObservableResult<Success, NextFailure> {
		current.next(transformer)
	}
}
