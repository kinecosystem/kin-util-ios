//
// Miscellaneous+extensions.swift
// KinUtil
//
// Created by Kin Foundation.
// Copyright © 2018 Kin Foundation. All rights reserved.
//

import Foundation

extension FixedWidthInteger {
    subscript(range: Range<Int>) -> Self {
        return self[range.lowerBound, range.upperBound - 1]
    }

    subscript(range: ClosedRange<Int>) -> Self {
        return self[range.lowerBound, range.upperBound]
    }

    subscript(bit: Int) -> Self {
        return self[bit, bit]
    }

    subscript(from: Int, to: Int) -> Self {
        precondition(from < Self.bitWidth, "from out of range")
        precondition(to < Self.bitWidth, "to out of range")
        precondition(from <= to, "from greater than to")

        var mask = 0 as Self
        for _ in 0 ..< (to + 1) - from { mask = (mask << 1) | 1 }
        mask = mask << from

        return (self & mask) >> from
    }
}
