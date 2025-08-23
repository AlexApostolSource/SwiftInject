//
//  Injected.swift
//  SwiftInject
//
//  Created by Alex.personal on 23/8/25.
//

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
