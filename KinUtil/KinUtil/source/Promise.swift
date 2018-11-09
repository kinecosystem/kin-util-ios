//
//  Promise.swift
//  KinUtil
//
//  Created by Kin Foundation.
//  Copyright © 2018 Kin Foundation. All rights reserved.
//

import Foundation
import Dispatch

enum Result<Value> {
    case success(Value)
    case failure(Error)

    func unwrap() throws -> Value {
        switch self {
        case .success(let v): return v
        case .failure(let e): throw e
        }
    }
}

public class Future<Value> {
    typealias Observer = (Result<Value>) -> ()

    var result: Result<Value>? {
        didSet {
            guard oldValue == nil else { return }

            result.map(report)
        }
    }

    var callbacks = [Observer]()

    func observe(with observer: @escaping Observer) {
        callbacks.append(observer)

        result.map(observer)
    }

    func report(_ result: Result<Value>) {
        callbacks.forEach { $0(result) }
    }
}

public final class Promise<Value>: Future<Value> {
    override public init() {

    }

    public convenience init(_ value: Value) {
        self.init()
        result = result ?? .success(value)
    }

    public convenience init(_ error: Error) {
        self.init()
        result = result ?? .failure(error)
    }

    @discardableResult
    public func signal(_ value: Value) -> Promise {
        result = result ?? .success(value)

        return self
    }

    @discardableResult
    public func signal(_ error: Error) -> Promise {
        result = result ?? .failure(error)

        return self
    }
}

extension Promise: CustomDebugStringConvertible {
    public var debugDescription: String {
        return "Promise [\(Unmanaged<AnyObject>.passUnretained(self as AnyObject).toOpaque())]"
    }
}

extension Promise {
    public func then<NewValue>(on queue: DispatchQueue? = nil,
                               _ handler: @escaping (Value) throws -> Promise<NewValue>) -> Promise<NewValue> {
        let np = Promise<NewValue>()

        observe { result in
            let block = {
                do {
                    try handler(result.unwrap())
                        .observe(with: { result in
                            np.result = result
                        })
                }
                catch {
                    np.signal(error)
                }
            }

            if let queue = queue {
                queue.async { block() }
            }
            else {
                block()
            }
        }

        return np
    }

    func then<NewValue>(on queue: DispatchQueue? = nil,
                        _ handler: @escaping (Value) throws -> NewValue) -> Promise<NewValue> {
        let np = Promise<NewValue>()

        observe { result in
            let block = {
                do {
                    np.signal(try handler(try result.unwrap()))
                }
                catch {
                    np.signal(error)
                }
            }

            if let queue = queue {
                queue.async { block() }
            }
            else {
                block()
            }
        }

        return np
    }

    @discardableResult
    public func then(on queue: DispatchQueue? = nil,
                     _ handler: @escaping (Value) -> ()) -> Promise<Value> {
        observe { result in
            let block = {
                if case let .success(value) = result {
                    handler(value)
                }
            }

            if let queue = queue {
                queue.async { block() }
            }
            else {
                block()
            }
        }

        return self
    }

    public func finally(on queue: DispatchQueue? = nil,
                        _ handler: @escaping () -> ()) {
        observe { _ in
            let block = {
                handler()
            }

            if let queue = queue {
                queue.async { block() }
            }
            else {
                block()
            }
        }
    }

    @discardableResult
    public func error(on queue: DispatchQueue? = nil,
                      _ handler: @escaping (Error) -> ()) -> Promise<Value> {
        observe { result in
            let block = {
                if case let .failure(error) = result {
                    handler(error)
                }
            }

            if let queue = queue {
                queue.async { block() }
            }
            else {
                block()
            }
        }

        return self
    }

    @discardableResult
    public func mapError(_ handler: @escaping (Error) -> (Error)) -> Promise<Value> {
        let p = Promise<Value>()

        observe { result in
            switch result {
            case .success(let value): p.signal(value)
            case .failure(let error): p.signal(handler(error))
            }
        }

        return p
    }

    @discardableResult
    @available(*, deprecated, renamed: "mapError(_:)")
    public func transformError(_ handler: @escaping (Error) -> (Error)) -> Promise<Value> {
        return mapError(handler)
    }
}


public func attempt<T>(_ tries: Int, retryInterval: TimeInterval = 0.0, closure: @escaping (Int) throws -> Promise<T>) -> Promise<T> {
    return attempt(retryIntervals: Array(repeating: retryInterval, count: tries - 1), closure: closure)
}

public func attempt<T>(retryIntervals: [TimeInterval], closure: @escaping (Int) throws -> Promise<T>) -> Promise<T> {
    let p = Promise<T>()

    let tries = retryIntervals.count + 1

    var attempts = 0

    var attempt2 = {}

    let attempt1 = {
        attempts += 1

        do {
            try closure(attempts)
                .then({
                    p.signal($0)
                })
                .error({
                    if attempts < tries {
                        DispatchQueue.global().asyncAfter(deadline: .now() + retryIntervals[attempts - 1]) {
                            attempt2()
                        }

                        return
                    }

                    p.signal($0)
                })
        }
        catch {
            p.signal(error)
        }
    }

    attempt2 = {
        attempts += 1

        do {
            try closure(attempts)
                .then({
                    p.signal($0)
                })
                .error({
                    if attempts < tries {
                        DispatchQueue.global().asyncAfter(deadline: .now() + retryIntervals[attempts - 1]) {
                            attempt1()
                        }

                        return
                    }

                    p.signal($0)
                })
        }
        catch {
            p.signal(error)
        }
    }

    attempt1()

    return p
}
