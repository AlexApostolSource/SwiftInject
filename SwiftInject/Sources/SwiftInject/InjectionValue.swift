//
//  InjectionValue.swift
//  SwiftInject
//
//  Created by Alex.personal on 23/8/25.
//

import Foundation

/// Provides access to injected dependencies.
public struct InjectedValues: @unchecked Sendable {
    /// This is only used as an accessor to the computed properties within extensions of `InjectedValues`.
    nonisolated(unsafe) static var current = InjectedValues()

    /// Thread-safe lock for protecting access to dependency values
    static let lock = NSRecursiveLock()

    /// Centralized dictionary to store overridden dependency values
    nonisolated(unsafe) private static var overrides: [ObjectIdentifier: Any] = [:]

    /// Track registered KeyPaths to prevent duplicates
    nonisolated(unsafe) private static var registeredKeyPaths: Set<String> = []

    /// A static subscript for updating the `currentValue` of `InjectionKey` instances.
    static subscript<K>(key: K.Type) -> K.Value where K : InjectionKey {
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

                // Check if this key is already registered
                if overrides[keyId] != nil {
                    let keyName = String(describing: key)
                    fatalError("Duplicate dependency registration detected for key: \(keyName). Dependencies can only be registered once.")
                }

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
            lock.withLock {
                let keyPathString = String(describing: keyPath)

                // Check if this KeyPath is already registered
                if registeredKeyPaths.contains(keyPathString) {
                    fatalError("Duplicate dependency registration detected for keyPath: \(keyPathString). Dependencies can only be registered once.")
                }

                registeredKeyPaths.insert(keyPathString)
                current[keyPath: keyPath] = newValue
            }
        }
    }

    /// Reset all dependencies to their default values (useful for testing)
    static func reset() {
        lock.withLock {
            overrides.removeAll()
            registeredKeyPaths.removeAll()
            current = InjectedValues()
        }
    }
}
