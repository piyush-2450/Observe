//
//  OBValue.swift
//  Observe
//
//  Created by Piyush Banerjee on 30/12/24.
//

// swiftlint:disable file_types_order
public typealias OBValue<T> = ObservableValue<T>
public typealias OBGrid<T> = ObservableGrid<T>
public typealias OBResult<
	Success,
	Failure: Error
> = ObservableResult<
	Success,
	Failure
>
// swiftlint:enable file_types_order
