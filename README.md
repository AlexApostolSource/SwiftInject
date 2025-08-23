# SwiftInject

A Swift dependency injection library for iOS and macOS applications using a clean, static API.
## [Documentation](https://deepwiki.com/AlexApostolSource/SwiftInject)
## Overview

SwiftInject is a lightweight and powerful dependency injection framework designed specifically for Swift projects. It provides a clean and intuitive way to manage dependencies through static methods and property wrappers, making dependency injection simple and type-safe.

## Features

- 🚀 **Lightweight**: Minimal overhead with maximum performance
- 🔧 **Type-safe**: Leverages Swift's strong type system
- 🎯 **Simple API**: Clean static methods and property wrappers
- 📱 **iOS & macOS**: Full support for Apple platforms
- 🧪 **Testing**: Built with testability in mind
- 🔒 **Thread-safe**: Safe for concurrent access
- 🎨 **Two registration styles**: KeyPath-based and InjectionKey-based

## Requirements

- iOS 13.0+ / macOS 10.15+
- Swift 5.0+
- Xcode 12.0+

## Installation

### Swift Package Manager

Add SwiftInject to your project via Swift Package Manager by adding the following to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/AlexApostolSource/SwiftInject.git", from: "1.0.0")
]
```

Or add it directly through Xcode:
1. File → Add Package Dependencies
2. Enter: `https://github.com/AlexApostolSource/SwiftInject.git`
3. Click Add Package

## Quick Start

### Using KeyPath Registration

```swift
import SwiftInject

// 1. Define your services
protocol APIService {
    func fetchData() -> String
}

class APIServiceImpl: APIService {
    func fetchData() -> String {
        return "API Data"
    }
}

// 2. Extend InjectedValues with your dependencies
extension InjectedValues {
    var apiService: APIService {
        get { Self[APIServiceKey.self] }
        set { Self[APIServiceKey.self] = newValue }
    }
}

// 3. Register dependencies using static methods
DependencyContainer.register(\.apiService, APIServiceImpl())

// 4. Use with property wrapper
class ViewModel {
    @Injected(\.apiService) var apiService: APIService
    
    func loadData() {
        let data = apiService.fetchData()
        print(data)
    }
}
```

### Using InjectionKey Registration

```swift
// 1. Create an InjectionKey
struct APIServiceKey: InjectionKey {
    static var currentValue: APIService = MockAPIService()
}

// 2. Register using the key directly
DependencyContainer.register(APIServiceKey.self, APIServiceImpl())

// 3. Resolve when needed
let service = DependencyContainer.resolve(APIServiceKey.self)
```

## Advanced Usage

### Property Wrapper Injection

```swift
class UserViewModel: ObservableObject {
    @Injected(\.apiService) var apiService: APIService
    @Injected(\.userRepository) var userRepository: UserRepository
    
    func loadUsers() {
        let users = userRepository.fetchUsers()
        // Use your injected dependencies
    }
}
```

### Manual Resolution

```swift
// Resolve using KeyPath
let apiService = DependencyContainer.resolve(\.apiService)

// Resolve using InjectionKey
let config = DependencyContainer.resolve(ConfigKey.self)
```

### Testing Support

SwiftInject makes testing easy with built-in reset functionality:

```swift
class UserViewModelTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Reset all dependencies before each test
        DependencyContainer.reset()
    }
    
    override func tearDown() {
        DependencyContainer.reset()
        super.tearDown()
    }
    
    func testUserLoading() {
        // Register mock for testing
        DependencyContainer.register(\.apiService, MockAPIService())
        
        let viewModel = UserViewModel()
        // Test with mock dependency
    }
}
```

## Architecture Patterns

### InjectionKey Pattern

Create keys for your dependencies:

```swift
struct NetworkServiceKey: InjectionKey {
    static var currentValue: NetworkService = DefaultNetworkService()
}

struct ConfigKey: InjectionKey {
    nonisolated(unsafe) static var currentValue: String = "default config"
}
```

### KeyPath Pattern

Extend `InjectedValues` with computed properties:

```swift
extension InjectedValues {
    var networkService: NetworkService {
        get { Self[NetworkServiceKey.self] }
        set { Self[NetworkServiceKey.self] = newValue }
    }
    
    var apiConfig: String {
        get { Self[ConfigKey.self] }
        set { Self[ConfigKey.self] = newValue }
    }
}
```

## API Reference

### DependencyContainer

```swift
// Registration methods
static func register<T>(_ keyPath: WritableKeyPath<InjectedValues, T>, _ instance: T)
static func register<K: InjectionKey>(_ keyType: K.Type, _ instance: K.Value)

// Resolution methods  
static func resolve<T>(_ keyPath: WritableKeyPath<InjectedValues, T>) -> T
static func resolve<K: InjectionKey>(_ keyType: K.Type) -> K.Value

// Testing support
static func reset() // Resets all dependencies to defaults
```

### Property Wrapper

```swift
@Injected(\.dependency) var dependency: DependencyType
```

## Thread Safety

SwiftInject is designed to be thread-safe with internal locking mechanisms that protect against concurrent access during registration and resolution.

## Best Practices

1. **Use KeyPath registration** for cleaner syntax
2. **Register dependencies early** in your app lifecycle
3. **Use reset() in tests** to ensure clean state
4. **Prefer protocol-based dependencies** for better testability
5. **Register once per dependency** - duplicate registrations will cause fatal errors

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

1. Fork the project
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Author

**Alex Apostol** - [@AlexApostolSource](https://github.com/AlexApostolSource)

## Acknowledgments

- Inspired by SwiftUI's Environment system
- Built with Swift's modern features and type safety in mind
- Community feedback and contributions

---

⭐ If you find SwiftInject helpful, please consider giving it a star!
