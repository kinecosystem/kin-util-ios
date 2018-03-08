//
//  Utility.swift
//  KinUtil
//
//  Created by Kin Foundation.
//  Copyright © 2018 Kin Foundation. All rights reserved.
//

import Foundation

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
