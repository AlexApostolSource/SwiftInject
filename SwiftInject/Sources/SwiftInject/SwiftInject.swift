import Foundation

public protocol InjectionKey {
    /// The associated type representing the type of the dependency injection key's value.
    associatedtype Value
    /// The default value for the dependency injection key.
    static var currentValue: Self.Value { get set }
}

/// Provides access to injected dependencies.
public struct InjectedValues: @unchecked Sendable {
    /// This is only used as an accessor to the computed properties within extensions of `InjectedValues`.
    nonisolated(unsafe) static var current = InjectedValues()

    /// Thread-safe lock for protecting access to dependency values
    static let lock = NSRecursiveLock()

    /// Centralized dictionary to store overridden dependency values
    nonisolated(unsafe) private static var overrides: [ObjectIdentifier: Any] = [:]

    /// A static subscript for updating the `currentValue` of `InjectionKey` instances.
    public static subscript<K>(key: K.Type) -> K.Value where K : InjectionKey {
        get {
            lock.withLock {
                let keyId = ObjectIdentifier(key)
                if let override = overrides[keyId] as? K.Value {
                    return override
                }
                return key.currentValue
            }
        }
        set {
            lock.withLock {
                let keyId = ObjectIdentifier(key)
                overrides[keyId] = newValue
            }
        }
    }

    /// A static subscript accessor for updating and references dependencies directly.
    static subscript<T>(_ keyPath: WritableKeyPath<InjectedValues, T>) -> T {
        get {
            lock.withLock { current[keyPath: keyPath] }
        }
        set {
            lock.withLock { current[keyPath: keyPath] = newValue }
        }
    }

    /// Reset all dependencies to their default values (useful for testing)
    static func reset() {
        lock.withLock {
            overrides.removeAll()
            current = InjectedValues()
        }
    }
}

@propertyWrapper
public struct Injected<T>: @unchecked Sendable {
    private let keyPath: WritableKeyPath<InjectedValues, T>
    public var wrappedValue: T {
        get { InjectedValues[keyPath] }
        set { InjectedValues[keyPath] = newValue }
    }

    public init(_ keyPath: WritableKeyPath<InjectedValues, T>) {
        self.keyPath = keyPath
    }
}

/// Centralized dependency registration container
public struct DependencyContainer {
    /// Register a dependency using a key path
    public static func register<T>(_ keyPath: WritableKeyPath<InjectedValues, T>, _ instance: T) {
        InjectedValues[keyPath] = instance
    }

    /// Register a dependency using an injection key
    public static func register<K: InjectionKey>(_ keyType: K.Type, _ instance: K.Value) {
        InjectedValues[keyType] = instance
    }

    /// Reset all dependencies to their default values (useful for testing)
    public static func reset() {
        InjectedValues.reset()
    }

    /// Get the current value of a dependency
    public static func resolve<T>(_ keyPath: WritableKeyPath<InjectedValues, T>) -> T {
        InjectedValues[keyPath]
    }

    /// Get the current value using an injection key
    public static func resolve<K: InjectionKey>(_ keyType: K.Type) -> K.Value {
        InjectedValues[keyType]
    }
}
