//
//  Utility.swift
//  KinUtil
//
//  Created by Kin Foundation.
//  Copyright © 2018 Kin Foundation. All rights reserved.
//

import Foundation
import Dispatch

struct AwaitTimeout: Error { }

public func serialize<Return>(_ task: (@escaping (Return?, Error?) -> ()) -> ()) throws -> Return? {
    let dispatchGroup = DispatchGroup()
    dispatchGroup.enter()

    var errorToThrow: Error? = nil
    var returnValue: Return? = nil

    task { (value: Return?, error: Error?) -> Void in
        errorToThrow = error
        returnValue = value

        dispatchGroup.leave()
    }

    dispatchGroup.wait()

    if let error = errorToThrow {
        throw error
    }

    return returnValue
}

public func promise<Return>(_ task: (@escaping (Return?, Error?) -> ()) -> ()) -> Promise<Return> {
    let p = Promise<Return>()

    task { (value: Return?, error: Error?) -> Void in
        if let error = error {
            p.signal(error)
        }

        if let value = value {
            p.signal(value)
        }
    }

    return p
}

public func promise<T>(_ futures: [Future<T>], timeout: TimeInterval? = nil) -> Promise<[T]> {
    let p = Promise<[T]>()

    DispatchQueue.global().async {
        do {
            p.signal(try await(futures, timeout: timeout))
        }
        catch {
            p.signal(error)
        }
    }

    return p
}

public func observable<Return>(_ task: (@escaping (Return?, Error?) -> ()) -> ()) -> Observable<Return> {
    let o = Observable<Return>()

    task { (value: Return?, error: Error?) -> Void in
        if let error = error {
            o.error(error)
        }

        if let value = value {
            o.next(value)
            o.finish()
        }
    }

    return o
}

public func await<T>(_ futures: [Future<T>], timeout: TimeInterval? = nil) throws -> [T] {
    let group = DispatchGroup()

    var results = [Result<T>]()

    for future in futures {
        group.enter()

        future.observe {
            results.append($0)

            group.leave()
        }
    }

    let wait = group.wait(timeout: timeout != nil ? .now() + timeout! : DispatchTime.distantFuture)

    if wait == DispatchTimeoutResult.timedOut { throw AwaitTimeout() }

    return try results.map { try $0.unwrap() }
}
