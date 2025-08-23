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

    func testInjectionKeyDefaultValue() {
        let service = InjectedValues[MockServiceKey.self]
        XCTAssertEqual(service.getValue(), "default")
    }

    func testInjectionKeyOverride() {
        let testService = TestMockService()
        InjectedValues[MockServiceKey.self] = testService

        let service = InjectedValues[MockServiceKey.self]
        XCTAssertEqual(service.getValue(), "test")
    }

    func testMultipleInjectionKeys() {
        InjectedValues[StringKey.self] = "custom string"
        InjectedValues[IntKey.self] = 100

        XCTAssertEqual(InjectedValues[StringKey.self], "custom string")
        XCTAssertEqual(InjectedValues[IntKey.self], 100)
    }

    // MARK: - KeyPath Tests

    func testKeyPathAccess() {
        let service = InjectedValues[\.mockService]
        XCTAssertEqual(service.getValue(), "default")
    }

    func testKeyPathOverride() {
        let testService = TestMockService()
        InjectedValues[\.mockService] = testService

        let service = InjectedValues[\.mockService]
        XCTAssertEqual(service.getValue(), "test")
    }

    // MARK: - PropertyWrapper Tests

    func testInjectedPropertyWrapper() {
        class TestClass {
            @Injected(\.mockService) var service: MockService
        }

        let testInstance = TestClass()
        XCTAssertEqual(testInstance.service.getValue(), "default")
    }

    func testInjectedPropertyWrapperWithOverride() {
        class TestClass {
            @Injected(\.mockService) var service: MockService
        }

        DependencyContainer.register(\.mockService, TestMockService())

        let testInstance = TestClass()
        XCTAssertEqual(testInstance.service.getValue(), "test")
    }

    func testInjectedPropertyWrapperSetter() {
        class TestClass {
            @Injected(\.testString) var value: String
        }

        let testInstance = TestClass()
        testInstance.value = "modified"

        XCTAssertEqual(testInstance.value, "modified")
        XCTAssertEqual(InjectedValues[\.testString], "modified")
    }

    // MARK: - DependencyContainer Tests

    func testDependencyContainerRegisterWithKeyPath() {
        DependencyContainer.register(\.mockService, TestMockService())

        let service = DependencyContainer.resolve(\.mockService)
        XCTAssertEqual(service.getValue(), "test")
    }

    func testDependencyContainerRegisterWithInjectionKey() {
        let testService = TestMockService()
        DependencyContainer.register(MockServiceKey.self, testService)

        let service = DependencyContainer.resolve(MockServiceKey.self)
        XCTAssertEqual(service.getValue(), "test")
    }

    func testDependencyContainerResolveWithKeyPath() {
        InjectedValues[\.testString] = "custom"

        let value = DependencyContainer.resolve(\.testString)
        XCTAssertEqual(value, "custom")
    }

    func testDependencyContainerResolveWithInjectionKey() {
        InjectedValues[StringKey.self] = "custom"

        let value = DependencyContainer.resolve(StringKey.self)
        XCTAssertEqual(value, "custom")
    }

    // MARK: - Reset Tests

    func testResetWithKeyPath() {
        DependencyContainer.register(\.mockService, TestMockService())
        XCTAssertEqual(DependencyContainer.resolve(\.mockService).getValue(), "test")

        DependencyContainer.reset()

        let service = DependencyContainer.resolve(\.mockService)
        XCTAssertEqual(service.getValue(), "default")
    }

    func testResetWithInjectionKey() {
        DependencyContainer.register(StringKey.self, "custom")
        XCTAssertEqual(DependencyContainer.resolve(StringKey.self), "custom")

        DependencyContainer.reset()

        XCTAssertEqual(DependencyContainer.resolve(StringKey.self), "default string")
    }

    func testResetResetsAllDependencies() {
        DependencyContainer.register(\.mockService, TestMockService())
        DependencyContainer.register(StringKey.self, "custom")
        DependencyContainer.register(IntKey.self, 999)

        DependencyContainer.reset()

        XCTAssertEqual(DependencyContainer.resolve(\.mockService).getValue(), "default")
        XCTAssertEqual(DependencyContainer.resolve(StringKey.self), "default string")
        XCTAssertEqual(DependencyContainer.resolve(IntKey.self), 42)
    }

    // MARK: - Thread Safety Tests

    func testConcurrentAccess() {
        let expectation = XCTestExpectation(description: "Concurrent access completed")
        expectation.expectedFulfillmentCount = 100

        let queue = DispatchQueue.global(qos: .default)

        for i in 0..<100 {
            queue.async {
                DependencyContainer.register(IntKey.self, i)
                let value = DependencyContainer.resolve(IntKey.self)
                XCTAssertTrue(value >= 0 && value < 100)
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 5.0)
    }

    func testConcurrentResetAndAccess() {
        let expectation = XCTestExpectation(description: "Concurrent reset and access completed")
        expectation.expectedFulfillmentCount = 50

        let queue = DispatchQueue.global(qos: .default)

        // Registrar valor inicial
        DependencyContainer.register(StringKey.self, "initial")

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

        wait(for: [expectation], timeout: 5.0)
    }

    // MARK: - Integration Tests

    func testCompleteWorkflow() {
        // Test de flujo completo
        class ServiceConsumer {
            @Injected(\.mockService) var service: MockService
            @Injected(\.testString) var message: String

            func process() -> String {
                return "\(message): \(service.getValue())"
            }
        }

        let consumer = ServiceConsumer()

        // Valores por defecto
        XCTAssertEqual(consumer.process(), "default string: default")

        // Registrar dependencias
        DependencyContainer.register(\.mockService, TestMockService())
        DependencyContainer.register(\.testString, "Hello")

        // Verificar cambios
        XCTAssertEqual(consumer.process(), "Hello: test")

        // Reset
        DependencyContainer.reset()

        // Verificar reset
        XCTAssertEqual(consumer.process(), "default string: default")
    }
}
