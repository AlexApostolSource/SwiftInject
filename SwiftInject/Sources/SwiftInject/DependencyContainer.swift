import Foundation

/// Centralized dependency registration container
public struct DependencyContainer: Sendable {
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
