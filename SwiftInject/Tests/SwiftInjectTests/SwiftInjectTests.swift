import XCTest
@testable import SwiftInject

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
        DependencyContainer.reset()
    }

    override func tearDown() {
        DependencyContainer.reset()
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

    func test_injectedPropertyWrapper_whenDependencyRegistered_shouldInjectRegisteredValue() {
        // Given: Class with injected property and registered dependency
        class TestClass {
            @Injected(\.mockService) var service: MockService
        }
        DependencyContainer.register(\.mockService, TestMockService())

        // When: Creating instance
        let testInstance = TestClass()

        // Then: Should inject registered value
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

    // MARK: - DependencyContainer Registration Tests

    func test_dependencyContainer_whenRegisteringWithKeyPath_shouldResolveRegisteredValue() {
        // Given: Test service instance
        let testService = TestMockService()

        // When: Registering dependency with keyPath
        DependencyContainer.register(\.mockService, testService)
        let resolvedService = DependencyContainer.resolve(\.mockService)

        // Then: Should resolve registered value
        XCTAssertEqual(resolvedService.getValue(), "test")
    }

    func test_dependencyContainer_whenRegisteringWithInjectionKey_shouldResolveRegisteredValue() {
        // Given: Test service instance
        let testService = TestMockService()

        // When: Registering dependency with injection key
        DependencyContainer.register(MockServiceKey.self, testService)
        let resolvedService = DependencyContainer.resolve(MockServiceKey.self)

        // Then: Should resolve registered value
        XCTAssertEqual(resolvedService.getValue(), "test")
    }

    func test_dependencyContainer_whenResolvingWithKeyPath_shouldReturnCurrentValue() {
        // Given: Modified global state
        InjectedValues[\.testString] = "custom"

        // When: Resolving with keyPath
        let resolvedValue = DependencyContainer.resolve(\.testString)

        // Then: Should return current value
        XCTAssertEqual(resolvedValue, "custom")
    }

    func test_dependencyContainer_whenResolvingWithInjectionKey_shouldReturnCurrentValue() {
        // Given: Modified global state
        InjectedValues[StringKey.self] = "custom"

        // When: Resolving with injection key
        let resolvedValue = DependencyContainer.resolve(StringKey.self)

        // Then: Should return current value
        XCTAssertEqual(resolvedValue, "custom")
    }

    // MARK: - Reset Functionality Tests

    func test_reset_whenCalledAfterKeyPathRegistration_shouldRestoreDefaultValue() {
        // Given: Registered dependency
        DependencyContainer.register(\.mockService, TestMockService())
        XCTAssertEqual(DependencyContainer.resolve(\.mockService).getValue(), "test")

        // When: Resetting container
        DependencyContainer.reset()

        // Then: Should restore default value
        let service = DependencyContainer.resolve(\.mockService)
        XCTAssertEqual(service.getValue(), "default")
    }

    func test_reset_whenCalledAfterInjectionKeyRegistration_shouldRestoreDefaultValue() {
        // Given: Registered dependency
        DependencyContainer.register(StringKey.self, "custom")
        XCTAssertEqual(DependencyContainer.resolve(StringKey.self), "custom")

        // When: Resetting container
        DependencyContainer.reset()

        // Then: Should restore default value
        XCTAssertEqual(DependencyContainer.resolve(StringKey.self), "default string")
    }

    func test_reset_whenMultipleDependenciesRegistered_shouldRestoreAllDefaultValues() {
        // Given: Multiple registered dependencies
        DependencyContainer.register(\.mockService, TestMockService())
        DependencyContainer.register(StringKey.self, "custom")
        DependencyContainer.register(IntKey.self, 999)

        // When: Resetting container
        DependencyContainer.reset()

        // Then: Should restore all default values
        XCTAssertEqual(DependencyContainer.resolve(\.mockService).getValue(), "default")
        XCTAssertEqual(DependencyContainer.resolve(StringKey.self), "default string")
        XCTAssertEqual(DependencyContainer.resolve(IntKey.self), 42)
    }

    // MARK: - Thread Safety Tests

    func test_concurrentAccess_whenMultipleThreadsModifying_shouldMaintainDataIntegrity() {
        // Given: Concurrent execution expectation
        let expectation = XCTestExpectation(description: "Concurrent access completed")
        expectation.expectedFulfillmentCount = 100
        let queue = DispatchQueue.global(qos: .default)

        // When: Multiple threads modify and read simultaneously
        for i in 0..<100 {
            queue.async {
                DependencyContainer.register(IntKey.self, i)
                let value = DependencyContainer.resolve(IntKey.self)
                XCTAssertTrue(value >= 0 && value < 100)
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
        DependencyContainer.register(StringKey.self, "initial")

        // When: Multiple threads reset and access simultaneously
        for _ in 0..<25 {
            queue.async {
                DependencyContainer.reset()
                expectation.fulfill()
            }

            queue.async {
                let value = DependencyContainer.resolve(StringKey.self)
                XCTAssertTrue(value == "default string" || value == "initial")
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

        // When: Registering dependencies
        DependencyContainer.register(\.mockService, TestMockService())
        DependencyContainer.register(\.testString, "Hello")

        // Then: Should use registered values
        XCTAssertEqual(consumer.process(), "Hello: test")

        // When: Resetting container
        DependencyContainer.reset()

        // Then: Should return to default values
        XCTAssertEqual(consumer.process(), "default string: default")
    }
}
