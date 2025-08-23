//
//  InjectionKey.swift
//  SwiftInject
//
//  Created by Alex.personal on 23/8/25.
//

import Foundation

public protocol InjectionKey: Sendable {
    /// The associated type representing the type of the dependency injection key's value.
    associatedtype Value
    /// The default value for the dependency injection key.
    /// Marked as nonisolated(unsafe) to allow access from any context.
    /// Thread safety is ensured by the lock mechanism in `InjectedValues`.
    nonisolated(unsafe) static var currentValue: Self.Value { get set }
}
