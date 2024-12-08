@testable import Observe
import Testing

// swiftlint:disable no_magic_numbers
@Test
internal func test0001() async throws {
	let list: ObservableList<String> = .init(
		rows: 20,
		columns: 30
	)

	list[15, 16] = "15_16"

	#expect(list[15, 16] == "15_16")
	#expect(list[16, 15] == nil)

	var items: [String?] = []
	list.forEach { _, _, item in
		items.append(item?.value)
	}

	#expect(items.count == 1)
}

@Test
internal func test0002() async throws {
	let list: ObservableList<String> = .init(
		rows: 20,
		columns: 30
	)

	#expect(list[15, 16]?.observerCount == nil)

	var observedValue: String?
	let ref: ObservableValue<String?>.ObserverRef? = list
		.observe(15, 16) { value in
			#expect(value == "15_16")
			observedValue = value
		}

	#expect(list[15, 16]?.observerCount == 1)

	list[15, 16] = "15_16"

	#expect(list[15, 16] == "15_16")
	#expect(list[16, 15] == nil)

	var items: [String?] = []
	list.forEach { _, _, item in
		items.append(item?.value)
	}

	#expect(items.count == 1)
	#expect(observedValue == "15_16")

	list.removeObserver(15, 16, ref)
	obQueue.sync(flags: .barrier) {
		#expect(list[15, 16]?.observerCount == nil)
	}
}
// swiftlint:enable no_magic_numbers
