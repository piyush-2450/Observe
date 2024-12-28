@testable import Observe
import Testing

// swiftlint:disable no_magic_numbers
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
// swiftlint:enable no_magic_numbers
