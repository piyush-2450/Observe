import Foundation
@testable import Observe
import Testing

// swiftlint:disable no_magic_numbers explicit_type_interface
@Test
internal func test0001() async throws {
	let grid: ObservableGrid<String> = .init(20, 30)

	grid[15, 16] = "15_16"

	#expect(grid[15, 16] == "15_16")
	#expect(grid[16, 15] == nil)

	var items: [String?] = []
	grid.forEach { _, item in
		items.append(item?.value)
	}

	#expect(items.count == 1)
}

@Test
internal func test0002() async throws {
	let grid: ObservableGrid<String> = .init(20, 30)

	#expect(grid[15, 16]?.observerCount == nil)

	var observedValue: String?
	let ref: ObservableValue<String?>.ObserverRef? = grid
		.observe(15, 16) { value in
			#expect(value == "15_16")
			observedValue = value
		}

	#expect(grid[15, 16]?.observerCount == 1)

	grid[15, 16] = "15_16"

	#expect(grid[15, 16] == "15_16")
	#expect(grid[16, 15] == nil)

	var items: [String?] = []
	grid.forEach { _, item in
		items.append(item?.value)
	}

	#expect(items.count == 1)
	#expect(observedValue == "15_16")

	grid.removeObserver(15, 16, ref: ref)
	obQueue.sync(flags: .barrier) {
		#expect(grid[15, 16]?.observerCount == nil)
	}
}

internal struct TestError: Error {
	let message: String

	init(_ message: String) {
		self.message = message
	}
}

@Test
internal func test0003() async throws {
	let head = OBResult<Int8, TestError>()
	let testValue: Int8 = 20

	func transformer1(_ input: Result<Int8, TestError>) -> Result<Int, TestError> {
		input.map { Int($0) }
	}

	func transformer2(_ input: Int) -> String {
		String(input)
	}

	let tail = head
	=> transformer1
	=> transformer2

	DispatchQueue
		.global(qos: .background)
		.asyncAfter(deadline: .now() + 1) {
			head.value = .success(testValue)
		}

	do {
		switch try await tail.wait() {
		case .success(let value):
			#expect(value == String(testValue))

		case .failure(let error):
			#expect(Bool(false), "Error: \(error.message)")

		case .none:
			#expect(Bool(false), "Error: Result is nil")
		}
	} catch {
		#expect(Bool(false), "Error: \(error.localizedDescription)")
	}
}
// swiftlint:enable no_magic_numbers explicit_type_interface
