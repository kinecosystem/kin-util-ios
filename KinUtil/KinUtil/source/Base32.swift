//
// Base32.swift
// KinUtil
//
// Created by Kin Foundation.
// Copyright © 2019 Kin Foundation. All rights reserved.
//

import Foundation

public enum Base32 {
    public static func encode<T: Sequence>(_ data: T) -> String where T.Element == UInt8 {
        var data = data.map { $0 }

        var s = ""

        let extraCount = (data.count % 5)
        let padding = ["", "======", "====", "===", "="][extraCount]

        let count = data.count
        data += Array(repeating: 0, count: 5 - extraCount)

        for i in stride(from: 0, to: count, by: 5) {
            s += toTable[(data[i + 0] & 0xF8) >> 3]!
            s += toTable[((data[i + 0] & 0x07) << 2) + ((data[i + 1] & 0xC0) >> 6)]!

            if i + 2 <= count {
                s += toTable[(data[i + 1] & 0x3E) >> 1]!
                s += toTable[((data[i + 1] & 0x01) << 4) + ((data[i + 2] & 0xF0) >> 4)]!
            }
            if i + 3 <= count {
                s += toTable[((data[i + 2] & 0x0F) << 1) + ((data[i + 3] & 0x80) >> 7)]!
            }
            if i + 4 <= count {
                s += toTable[(data[i + 3] & 0x7C) >> 2]!
                s += toTable[((data[i + 3] & 0x03) << 3) + ((data[i + 4] & 0xF8) >> 5)]!
            }
            if i + 5 <= count {
                s += toTable[(data[i + 4] & 0x1F)]!
            }
        }

        return s + padding
    }

    public static func decode(_ string: String) -> [UInt8] {
        var result = [UInt8]()

        for i in stride(from: 0, to: string.count, by: 8) {
            let start = string.index(string.startIndex, offsetBy: i)
            let end = string.index(start, offsetBy: min(string.count - i, 8))

            let s = string[start ..< end]

            let bytes = s.map { fromTable[String($0)]! }

            let paddings = ["=", "===", "====", "======"]
            var keepCount = 5

            for i in paddings.indices {
                if s.hasSuffix(paddings[i]) { keepCount -= 1}
            }

            result.append((bytes[0] << 3) + (bytes[1] >> 2))

            if keepCount > 1 {
                result.append((bytes[1] & 0x03) << 6 + (bytes[2] << 1) + bytes[3] >> 4)
            }

            if keepCount > 2 {
                result.append((bytes[3] & 0x0F) << 4 + (bytes[4] >> 1))
            }

            if keepCount > 3 {
                result.append(bytes[4] << 7 + (bytes[5] << 2) + (bytes[6] & 0x18) >> 3)
            }

            if keepCount > 4 {
                result.append((bytes[6] & 0x07) << 5 + bytes[7])
            }
        }

        return result
    }
}

private let fromTable: [String: UInt8] = [
    "A": 0b00000, "B": 0b00001, "C": 0b00010, "D": 0b00011, "E": 0b00100,
    "F": 0b00101, "G": 0b00110, "H": 0b00111, "I": 0b01000, "J": 0b01001,
    "K": 0b01010, "L": 0b01011, "M": 0b01100, "N": 0b01101, "O": 0b01110,
    "P": 0b01111, "Q": 0b10000, "R": 0b10001, "S": 0b10010, "T": 0b10011,
    "U": 0b10100, "V": 0b10101, "W": 0b10110, "X": 0b10111, "Y": 0b11000,
    "Z": 0b11001, "2": 0b11010, "3": 0b11011, "4": 0b11100, "5": 0b11101,
    "6": 0b11110, "7": 0b11111, "=": 0b00000,
]

private let toTable: [UInt8: String] = {
    var t = [UInt8: String]()

    for (k, v) in fromTable { t[v] = k }

    return t
}()
