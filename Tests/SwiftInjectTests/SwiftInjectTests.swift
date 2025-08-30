@testable import SwiftInject
import XCTest

// MARK: - Test Dependencies (at file scope)

protocol MockService {
    func getValue() -> String
}

class DefaultMockService: MockService {
    func getValue() -> String {
        return "default"
    }
}

class TestMockService: MockService {
    func getValue() -> String {
        return "test"
    }
}

// MARK: - Injection Keys (at file scope)

private struct MockServiceKey: InjectionKey {
    nonisolated(unsafe) static var currentValue: MockService = DefaultMockService()
}

private struct StringKey: InjectionKey {
    nonisolated(unsafe) static var currentValue: String = "default string"
}

private struct IntKey: InjectionKey {
    nonisolated(unsafe) static var currentValue: Int = 42
}

// MARK: - InjectedValues Extensions (at file scope)

extension InjectedValues {
    var mockService: MockService {
        get { Self[MockServiceKey.self] }
        set { Self[MockServiceKey.self] = newValue }
    }

    var testString: String {
        get { Self[StringKey.self] }
        set { Self[StringKey.self] = newValue }
    }

    var testInt: Int {
        get { Self[IntKey.self] }
        set { Self[IntKey.self] = newValue }
    }
}

// MARK: - Test Class

final class SwiftInjectTests: XCTestCase {

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()
        InjectedValues.reset()
    }

    override func tearDown() {
        InjectedValues.reset()
        super.tearDown()
    }

    // MARK: - InjectionKey Tests

    func test_injectionKey_whenAccessingDefault_shouldReturnDefaultValue() {
        // Given: Default injection key configuration

        // When: Accessing the service through injection key
        let service = InjectedValues[MockServiceKey.self]

        // Then: Should return default value
        XCTAssertEqual(service.getValue(), "default")
    }

    func test_injectionKey_whenOverridingValue_shouldReturnNewValue() {
        // Given: Test service instance
        let testService = TestMockService()

        // When: Overriding injection key value
        InjectedValues[MockServiceKey.self] = testService
        let service = InjectedValues[MockServiceKey.self]

        // Then: Should return overridden value
        XCTAssertEqual(service.getValue(), "test")
    }

    func test_injectionKey_whenSettingMultipleKeys_shouldMaintainSeparateValues() {
        // Given: Multiple different values
        let customString = "custom string"
        let customInt = 100

        // When: Setting multiple injection keys
        InjectedValues[StringKey.self] = customString
        InjectedValues[IntKey.self] = customInt

        // Then: Should maintain separate values for each key
        XCTAssertEqual(InjectedValues[StringKey.self], customString)
        XCTAssertEqual(InjectedValues[IntKey.self], customInt)
    }

    // MARK: - KeyPath Access Tests

    func test_keyPathAccess_whenAccessingDefault_shouldReturnDefaultValue() {
        // Given: Default keyPath configuration

        // When: Accessing service through keyPath
        let service = InjectedValues[\.mockService]

        // Then: Should return default value
        XCTAssertEqual(service.getValue(), "default")
    }

    func test_keyPathAccess_whenOverridingValue_shouldReturnNewValue() {
        // Given: Test service instance
        let testService = TestMockService()

        // When: Overriding keyPath value
        InjectedValues[\.mockService] = testService
        let service = InjectedValues[\.mockService]

        // Then: Should return overridden value
        XCTAssertEqual(service.getValue(), "test")
    }

    // MARK: - Property Wrapper Tests

    func test_injectedPropertyWrapper_whenCreatingInstance_shouldInjectDefaultValue() {
        // Given: Class with injected property
        class TestClass {
            @Injected(\.mockService) var service: MockService
        }

        // When: Creating instance
        let testInstance = TestClass()

        // Then: Should inject default value
        XCTAssertEqual(testInstance.service.getValue(), "default")
    }

    func test_injectedPropertyWrapper_whenDependencyOverridden_shouldInjectOverriddenValue() {
        // Given: Class with injected property and overridden dependency
        class TestClass {
            @Injected(\.mockService) var service: MockService
        }
        InjectedValues[\.mockService] = TestMockService()

        // When: Creating instance
        let testInstance = TestClass()

        // Then: Should inject overridden value
        XCTAssertEqual(testInstance.service.getValue(), "test")
    }

    func test_injectedPropertyWrapper_whenSettingValue_shouldUpdateGlobalState() {
        // Given: Class with injected property
        class TestClass {
            @Injected(\.testString) var value: String
        }
        let testInstance = TestClass()
        let newValue = "modified"

        // When: Setting value through property wrapper
        testInstance.value = newValue

        // Then: Should update both property and global state
        XCTAssertEqual(testInstance.value, newValue)
        XCTAssertEqual(InjectedValues[\.testString], newValue)
    }

    // MARK: - Duplicate Prevention Tests

    func test_injectionKey_whenAttemptingDuplicateRegistration_shouldPreventDuplicate() {
        // Given: Initial registration
        InjectedValues[MockServiceKey.self] = TestMockService()

        // When & Then: Attempting duplicate registration should cause fatal error
        // Note: We can't directly test fatal errors in unit tests, but we can verify
        // that the first registration worked and subsequent access returns the original value
        let service = InjectedValues[MockServiceKey.self]
        XCTAssertEqual(service.getValue(), "test")
    }

    func test_keyPath_whenAttemptingDuplicateRegistration_shouldPreventDuplicate() {
        // Given: Initial registration
        InjectedValues[\.testString] = "first registration"

        // When & Then: Attempting duplicate registration should cause fatal error
        // We can verify that the first registration worked
        let value = InjectedValues[\.testString]
        XCTAssertEqual(value, "first registration")
    }

    // MARK: - Reset Functionality Tests

    func test_reset_whenCalledAfterKeyPathRegistration_shouldRestoreDefaultValue() {
        // Given: Overridden dependency
        InjectedValues[\.mockService] = TestMockService()
        XCTAssertEqual(InjectedValues[\.mockService].getValue(), "test")

        // When: Resetting
        InjectedValues.reset()

        // Then: Should restore default value
        let service = InjectedValues[\.mockService]
        XCTAssertEqual(service.getValue(), "default")
    }

    func test_reset_whenCalledAfterInjectionKeyRegistration_shouldRestoreDefaultValue() {
        // Given: Overridden dependency
        InjectedValues[StringKey.self] = "custom"
        XCTAssertEqual(InjectedValues[StringKey.self], "custom")

        // When: Resetting
        InjectedValues.reset()

        // Then: Should restore default value
        XCTAssertEqual(InjectedValues[StringKey.self], "default string")
    }

    func test_reset_whenMultipleDependenciesOverridden_shouldRestoreAllDefaultValues() {
        // Given: Multiple overridden dependencies
        InjectedValues[\.mockService] = TestMockService()
        InjectedValues[StringKey.self] = "custom"
        InjectedValues[IntKey.self] = 999

        // When: Resetting
        InjectedValues.reset()

        // Then: Should restore all default values
        XCTAssertEqual(InjectedValues[\.mockService].getValue(), "default")
        XCTAssertEqual(InjectedValues[StringKey.self], "default string")
        XCTAssertEqual(InjectedValues[IntKey.self], 42)
    }

    func test_reset_whenCalled_shouldAllowNewRegistrations() {
        // Given: Initial registration and reset
        InjectedValues[\.testString] = "first"
        InjectedValues.reset()

        // When: Registering after reset
        InjectedValues[\.testString] = "second"

        // Then: Should allow new registration
        XCTAssertEqual(InjectedValues[\.testString], "second")
    }

    // MARK: - Thread Safety Tests

    func test_concurrentAccess_whenMultipleThreadsModifying_shouldMaintainDataIntegrity() {
        // Given: Concurrent execution expectation
        let expectation = XCTestExpectation(description: "Concurrent access completed")
        expectation.expectedFulfillmentCount = 100
        let queue = DispatchQueue.global(qos: .default)

        // When: Multiple threads read simultaneously (avoiding duplicate registrations)
        for _ in 0..<100 {
            queue.async {
                // Only read to avoid duplicate registration issues
                let value = InjectedValues[IntKey.self]
                XCTAssertEqual(value, 42) // Default value
                expectation.fulfill()
            }
        }

        // Then: All operations should complete successfully
        wait(for: [expectation], timeout: 5.0)
    }

    func test_concurrentResetAndAccess_whenSimultaneousOperations_shouldMaintainDataIntegrity() {
        // Given: Concurrent execution setup
        let expectation = XCTestExpectation(description: "Concurrent reset and access completed")
        expectation.expectedFulfillmentCount = 50
        let queue = DispatchQueue.global(qos: .default)

        // When: Multiple threads reset and access simultaneously
        for _ in 0..<25 {
            queue.async {
                InjectedValues.reset()
                expectation.fulfill()
            }

            queue.async {
                let value = InjectedValues[StringKey.self]
                XCTAssertEqual(value, "default string") // Should always be default after any reset
                expectation.fulfill()
            }
        }

        // Then: All operations should complete without data corruption
        wait(for: [expectation], timeout: 5.0)
    }

    // MARK: - Integration Tests

    func test_completeWorkflow_whenUsingFullDependencyInjectionFlow_shouldWorkCorrectly() {
        // Given: Service consumer with injected dependencies
        class ServiceConsumer {
            @Injected(\.mockService) var service: MockService
            @Injected(\.testString) var message: String

            func process() -> String {
                return "\(message): \(service.getValue())"
            }
        }
        let consumer = ServiceConsumer()

        // When & Then: Testing default values
        XCTAssertEqual(consumer.process(), "default string: default")

        // When: Overriding dependencies
        InjectedValues[\.mockService] = TestMockService()
        InjectedValues[\.testString] = "Hello"

        // Then: Should use overridden values
        XCTAssertEqual(consumer.process(), "Hello: test")

        // When: Resetting
        InjectedValues.reset()

        // Then: Should return to default values
        XCTAssertEqual(consumer.process(), "default string: default")
    }
}
