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
        let data = data.map { $0 }

        var binary = data.binaryString
        var s = ""

        let extraCount = (binary.count % 40)
        let padding = ["", "======", "====", "===", "="][(extraCount / 8)]

        let count = binary.count
        binary += String(repeating: "0", count: 40 - extraCount)

        for i in stride(from: 0, to: count, by: 5) {
            s += toTable[binary[i..<(i + 5)]]!
        }

        return s + padding
    }

    public static func decode(_ string: String) -> [UInt8] {
        let paddings = ["=", "===", "====", "======"]
        var paddingCount = 0

        for i in paddings.indices {
            if string.hasSuffix(paddings[i]) { paddingCount = i + 1}
        }

        let binary: String = string.reduce("") { $0 + fromTable[String($1)]! }

        var d = [UInt8]()

        for i: Int in stride(from: 0, to: binary.utf8.count - paddingCount * 8, by: 8) {
            let s: String = binary[i..<(i + 8)]
            d.append(UInt8(s, radix: 2)!)
        }

        return d
    }
}

private let fromTable: [String: String] = [
    "A": "00000", "B": "00001", "C": "00010", "D": "00011", "E": "00100",
    "F": "00101", "G": "00110", "H": "00111", "I": "01000", "J": "01001",
    "K": "01010", "L": "01011", "M": "01100", "N": "01101", "O": "01110",
    "P": "01111", "Q": "10000", "R": "10001", "S": "10010", "T": "10011",
    "U": "10100", "V": "10101", "W": "10110", "X": "10111", "Y": "11000",
    "Z": "11001", "2": "11010", "3": "11011", "4": "11100", "5": "11101",
    "6": "11110", "7": "11111",
]

private let toTable: [String: String] = {
    var t = [String: String]()

    for (k, v) in fromTable { t[v] = k }

    return t
}()
