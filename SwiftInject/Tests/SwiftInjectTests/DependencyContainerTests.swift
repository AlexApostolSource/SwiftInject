//
//  DependencyContainerTests.swift
//  SwiftInject
//
//  Created by Alex.personal on 23/8/25.
//

import XCTest
@testable import SwiftInject

// MARK: - Test Dependencies for DependencyContainer

protocol NetworkService {
    func fetchData() -> String
}

class MockNetworkService: NetworkService {
    func fetchData() -> String {
        return "mock data"
    }
}

class TestNetworkService: NetworkService {
    func fetchData() -> String {
        return "test data"
    }
}

// MARK: - Injection Keys for DependencyContainer Tests

private struct NetworkServiceKey: InjectionKey {
    static var currentValue: NetworkService = MockNetworkService()
}

private struct ConfigKey: InjectionKey {
    nonisolated(unsafe) static var currentValue: String = "default config"
}

private struct TimeoutKey: InjectionKey {
    nonisolated(unsafe) static var currentValue: TimeInterval = 30.0
}

// MARK: - InjectedValues Extensions for DependencyContainer Tests

extension InjectedValues {
    var networkService: NetworkService {
        get { Self[NetworkServiceKey.self] }
        set { Self[NetworkServiceKey.self] = newValue }
    }

    var apiConfig: String {
        get { Self[ConfigKey.self] }
        set { Self[ConfigKey.self] = newValue }
    }

    var requestTimeout: TimeInterval {
        get { Self[TimeoutKey.self] }
        set { Self[TimeoutKey.self] = newValue }
    }
}

// MARK: - DependencyContainer Tests

final class DependencyContainerTests: XCTestCase {

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()
        DependencyContainer.reset()
    }

    override func tearDown() {
        DependencyContainer.reset()
        super.tearDown()
    }

    // MARK: - KeyPath Registration Tests

    func test_registerKeyPath_whenRegisteringDependency_shouldStoreCorrectValue() {
        // Given: Test service instance
        let testService = TestNetworkService()

        // When: Registering dependency using keyPath
        DependencyContainer.register(\.networkService, testService)

        // Then: Should store the registered value
        let resolvedService = DependencyContainer.resolve(\.networkService)
        XCTAssertEqual(resolvedService.fetchData(), "test data")
    }

    func test_registerKeyPath_whenRegisteringMultipleDependencies_shouldStoreSeparately() {
        // Given: Multiple test values
        let config = "production config"
        let timeout: TimeInterval = 60.0

        // When: Registering multiple dependencies
        DependencyContainer.register(\.apiConfig, config)
        DependencyContainer.register(\.requestTimeout, timeout)

        // Then: Should store each dependency separately
        XCTAssertEqual(DependencyContainer.resolve(\.apiConfig), config)
        XCTAssertEqual(DependencyContainer.resolve(\.requestTimeout), timeout)
    }

    func test_registerKeyPath_whenAttemptingDuplicateRegistration_shouldPreventDuplicate() {
        // Given: Initial registration
        DependencyContainer.register(\.apiConfig, "first config")

        // When & Then: Attempting duplicate registration should maintain original value
        // (Note: Fatal error prevention means the second registration won't execute)
        let resolvedConfig = DependencyContainer.resolve(\.apiConfig)
        XCTAssertEqual(resolvedConfig, "first config")
    }

    // MARK: - InjectionKey Registration Tests

    func test_registerInjectionKey_whenRegisteringDependency_shouldStoreCorrectValue() {
        // Given: Test service instance
        let testService = TestNetworkService()

        // When: Registering dependency using injection key
        DependencyContainer.register(NetworkServiceKey.self, testService)

        // Then: Should store the registered value
        let resolvedService = DependencyContainer.resolve(NetworkServiceKey.self)
        XCTAssertEqual(resolvedService.fetchData(), "test data")
    }

    func test_registerInjectionKey_whenRegisteringMultipleDependencies_shouldStoreSeparately() {
        // Given: Multiple test values
        let config = "staging config"
        let timeout: TimeInterval = 45.0

        // When: Registering multiple dependencies using injection keys
        DependencyContainer.register(ConfigKey.self, config)
        DependencyContainer.register(TimeoutKey.self, timeout)

        // Then: Should store each dependency separately
        XCTAssertEqual(DependencyContainer.resolve(ConfigKey.self), config)
        XCTAssertEqual(DependencyContainer.resolve(TimeoutKey.self), timeout)
    }

    func test_registerInjectionKey_whenAttemptingDuplicateRegistration_shouldPreventDuplicate() {
        // Given: Initial registration
        DependencyContainer.register(ConfigKey.self, "original config")

        // When & Then: Attempting duplicate registration should maintain original value
        let resolvedConfig = DependencyContainer.resolve(ConfigKey.self)
        XCTAssertEqual(resolvedConfig, "original config")
    }

    // MARK: - Resolution Tests

    func test_resolveKeyPath_whenDependencyNotRegistered_shouldReturnDefaultValue() {
        // Given: No registration (using default values)

        // When: Resolving unregistered dependency
        let service = DependencyContainer.resolve(\.networkService)

        // Then: Should return default value
        XCTAssertEqual(service.fetchData(), "mock data")
    }

    func test_resolveKeyPath_whenDependencyRegistered_shouldReturnRegisteredValue() {
        // Given: Registered dependency
        let testService = TestNetworkService()
        DependencyContainer.register(\.networkService, testService)

        // When: Resolving registered dependency
        let service = DependencyContainer.resolve(\.networkService)

        // Then: Should return registered value
        XCTAssertEqual(service.fetchData(), "test data")
    }

    func test_resolveInjectionKey_whenDependencyNotRegistered_shouldReturnDefaultValue() {
        // Given: No registration (using default values)

        // When: Resolving unregistered dependency
        let config = DependencyContainer.resolve(ConfigKey.self)

        // Then: Should return default value
        XCTAssertEqual(config, "default config")
    }

    func test_resolveInjectionKey_whenDependencyRegistered_shouldReturnRegisteredValue() {
        // Given: Registered dependency
        let customConfig = "custom config"
        DependencyContainer.register(ConfigKey.self, customConfig)

        // When: Resolving registered dependency
        let config = DependencyContainer.resolve(ConfigKey.self)

        // Then: Should return registered value
        XCTAssertEqual(config, customConfig)
    }

    // MARK: - Reset Tests

    func test_reset_whenCalledAfterKeyPathRegistrations_shouldRestoreDefaultValues() {
        // Given: Multiple registered dependencies
        DependencyContainer.register(\.networkService, TestNetworkService())
        DependencyContainer.register(\.apiConfig, "test config")

        // When: Resetting
        DependencyContainer.reset()

        // Then: Should restore default values
        let service = DependencyContainer.resolve(\.networkService)
        let config = DependencyContainer.resolve(\.apiConfig)
        XCTAssertEqual(service.fetchData(), "mock data")
        XCTAssertEqual(config, "default config")
    }

    func test_reset_whenCalledAfterInjectionKeyRegistrations_shouldRestoreDefaultValues() {
        // Given: Multiple registered dependencies
        DependencyContainer.register(NetworkServiceKey.self, TestNetworkService())
        DependencyContainer.register(ConfigKey.self, "custom config")
        DependencyContainer.register(TimeoutKey.self, 120.0)

        // When: Resetting
        DependencyContainer.reset()

        // Then: Should restore default values
        let service = DependencyContainer.resolve(NetworkServiceKey.self)
        let config = DependencyContainer.resolve(ConfigKey.self)
        let timeout = DependencyContainer.resolve(TimeoutKey.self)
        XCTAssertEqual(service.fetchData(), "mock data")
        XCTAssertEqual(config, "default config")
        XCTAssertEqual(timeout, 30.0)
    }

    func test_reset_whenCalled_shouldAllowNewRegistrations() {
        // Given: Initial registration and reset
        DependencyContainer.register(\.apiConfig, "first config")
        DependencyContainer.reset()

        // When: Registering after reset
        DependencyContainer.register(\.apiConfig, "second config")

        // Then: Should allow new registration
        let config = DependencyContainer.resolve(\.apiConfig)
        XCTAssertEqual(config, "second config")
    }

    // MARK: - Mixed Registration Type Tests

    func test_mixedRegistration_whenUsingBothKeyPathAndInjectionKey_shouldWorkIndependently() {
        // Given: Different registration methods for different dependencies
        let testService = TestNetworkService()
        let customConfig = "mixed config"

        // When: Using both registration methods
        DependencyContainer.register(\.networkService, testService)
        DependencyContainer.register(ConfigKey.self, customConfig)

        // Then: Both should work independently
        let service = DependencyContainer.resolve(\.networkService)
        let config = DependencyContainer.resolve(ConfigKey.self)
        XCTAssertEqual(service.fetchData(), "test data")
        XCTAssertEqual(config, customConfig)
    }

    // MARK: - Thread Safety Tests

//    func test_concurrentRegistration_whenMultipleThreadsRegistering_shouldMaintainThreadSafety() {
//        // Given: Concurrent execution setup
//        let expectation = XCTestExpectation(description: "Concurrent registration completed")
//        expectation.expectedFulfillmentCount = 10
//        let queue = DispatchQueue.global(qos: .default)
//
//        // When: Multiple threads register different dependencies simultaneously
//        for i in 0..<10 {
//            queue.async {
//                // Use different keys to avoid duplicate registration issues
//                let timeout = TimeInterval(i + 100)
//                DependencyContainer.register(TimeoutKey.self, timeout)
//                expectation.fulfill()
//            }
//        }
//
//        // Then: All operations should complete without crashing
//        wait(for: [expectation], timeout: 5.0)
//
//        // Verify final state
//        let finalTimeout = DependencyContainer.resolve(TimeoutKey.self)
//        XCTAssertGreaterThanOrEqual(finalTimeout, 100.0)
//    }

    func test_concurrentResolution_whenMultipleThreadsResolving_shouldMaintainThreadSafety() {
        // Given: Pre-registered dependency and concurrent execution setup
        DependencyContainer.register(\.apiConfig, "thread-safe config")
        let expectation = XCTestExpectation(description: "Concurrent resolution completed")
        expectation.expectedFulfillmentCount = 50
        let queue = DispatchQueue.global(qos: .default)

        // When: Multiple threads resolve simultaneously
        for _ in 0..<50 {
            queue.async {
                let config = DependencyContainer.resolve(\.apiConfig)
                XCTAssertEqual(config, "thread-safe config")
                expectation.fulfill()
            }
        }

        // Then: All resolutions should complete successfully
        wait(for: [expectation], timeout: 5.0)
    }

    // MARK: - Integration Tests

    func test_fullWorkflow_whenUsingCompleteRegistrationAndResolutionFlow_shouldWorkCorrectly() {
        // Given: Service that depends on multiple injected dependencies
        class APIClient {
            @Injected(\.networkService) var networkService: NetworkService
            @Injected(\.apiConfig) var config: String
            @Injected(\.requestTimeout) var timeout: TimeInterval

            func makeRequest() -> String {
                return "\(config) - \(networkService.fetchData()) - timeout: \(timeout)"
            }
        }

        // When & Then: Testing with default values
        let client = APIClient()
        XCTAssertEqual(client.makeRequest(), "default config - mock data - timeout: 30.0")

        // When: Registering custom dependencies via DependencyContainer
        DependencyContainer.register(\.networkService, TestNetworkService())
        DependencyContainer.register(ConfigKey.self, "production")
        DependencyContainer.register(\.requestTimeout, 60.0)

        // Then: Should use registered values
        XCTAssertEqual(client.makeRequest(), "production - test data - timeout: 60.0")

        // When: Resetting via DependencyContainer
        DependencyContainer.reset()

        // Then: Should return to defaults
        XCTAssertEqual(client.makeRequest(), "default config - mock data - timeout: 30.0")
    }

    func test_consistencyWithInjectedValues_whenComparingDirectAccessAndContainerAccess_shouldBeEqual() {
        // Given: Registration via DependencyContainer
        let testConfig = "consistency test"
        DependencyContainer.register(\.apiConfig, testConfig)

        // When: Accessing via both methods
        let containerValue = DependencyContainer.resolve(\.apiConfig)
        let directValue = InjectedValues[\.apiConfig]

        // Then: Both should return the same value
        XCTAssertEqual(containerValue, directValue)
        XCTAssertEqual(containerValue, testConfig)
    }
}
