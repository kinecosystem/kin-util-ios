//
// ObservableTests.swift
// KinUtilTests
//
// Created by Kin Foundation.
// Copyright © 2019 Kin Foundation. All rights reserved.
//

import XCTest
@testable import KinUtil

class ObservableTests: XCTestCase {

    func test_next_before_observe() {
        let e = expectation(description: "")

        let o = SourceObservable<Int>()

        o.next(3)

        o.on(next: {
            XCTAssertEqual($0, 3)
            e.fulfill()
        })

        wait(for: [e], timeout: 1)
    }

    func test_next_after_observe() {
        let e = expectation(description: "")

        let o = SourceObservable<Int>()

        o.on(next: {
            XCTAssertEqual($0, 3)
            e.fulfill()
        })

        o.next(3)

        wait(for: [e], timeout: 1)
    }

    func test_pre_observer_buffering() {
        let e = expectation(description: "")

        let o = SourceObservable<Int>()

        o.next(3)
        o.next(2)
        o.next(1)

        var eventCounter = 3
        o.on(next: { _ in
            eventCounter -= 1

            if eventCounter == 0 { e.fulfill() }
        })

        wait(for: [e], timeout: 1)
    }

    func test_accumulate() {
        let e = expectation(description: "")

        let o = SourceObservable<Int>()
        let p = o.accumulate(limit: 3)

        o.next(3)
        o.next(2)
        o.next(1)

        var eventCounter = 3
        p.on(next: {
            eventCounter -= 1

            XCTAssertEqual($0.count, 3 - eventCounter)

            if eventCounter == 0 { e.fulfill() }
        })

        wait(for: [e], timeout: 1)
    }

    func test_accumulate_overflow() {
        let e = expectation(description: "")

        let o = SourceObservable<Int>()
        let p = o.accumulate(limit: 3)

        o.next(4)
        o.next(3)
        o.next(2)
        o.next(1)

        var eventCounter = 4
        p.on(next: {
            eventCounter -= 1

            XCTAssertLessThanOrEqual($0.count, 3)

            if eventCounter == 0 { e.fulfill() }
        })

        wait(for: [e], timeout: 1)
    }

    func test_combine_other_signal_primary() {
        let e = expectation(description: "")

        let o = SourceObservable<Int>()
        let p = SourceObservable<String>()
        let q = o.combine(with: p)

        o.next(3)

        q.on(next: {
            XCTAssertEqual($0.0, 3)
            XCTAssertEqual($0.1, nil)

            e.fulfill()
        })

        wait(for: [e], timeout: 1)
    }

    func test_combine_other_signal_other() {
        let e = expectation(description: "")

        let o = SourceObservable<Int>()
        let p = SourceObservable<String>()
        let q = o.combine(with: p)

        p.next("3")

        q.on(next: {
            XCTAssertEqual($0.0, nil)
            XCTAssertEqual($0.1, "3")

            e.fulfill()
        })

        wait(for: [e], timeout: 1)
    }

    func test_combine_other_signal_both() {
        let e = expectation(description: "")

        let o = SourceObservable<Int>()
        let p = SourceObservable<String>()
        let q = o.combine(with: p)

        o.next(3)
        p.next("3")

        var eventCounter = 2
        q.on(next: {
            eventCounter -= 1

            if eventCounter == 0 {
                XCTAssertEqual($0.0, 3)
                XCTAssertEqual($0.1, "3")

                e.fulfill()
            }
        })

        wait(for: [e], timeout: 1)
    }

    func test_combine_same_signal_primary() {
        let e = expectation(description: "")

        let o = SourceObservable<Int>()
        let p = SourceObservable<Int>()
        let q = SourceObservable<Int>()
        let r = o.combine(with: p, q)

        o.next(3)

        r.on(next: {
            XCTAssertEqual($0[0], 3)
            XCTAssertEqual($0[1], nil)
            XCTAssertEqual($0[2], nil)

            e.fulfill()
        })

        wait(for: [e], timeout: 1)
    }

    func test_combine_same_signal_other() {
        let e = expectation(description: "")

        let o = SourceObservable<Int>()
        let p = SourceObservable<Int>()
        let q = SourceObservable<Int>()
        let r = o.combine(with: p, q)

        p.next(3)

        r.on(next: {
            XCTAssertEqual($0[0], nil)
            XCTAssertEqual($0[1], 3)
            XCTAssertEqual($0[2], nil)

            e.fulfill()
        })

        wait(for: [e], timeout: 1)
    }

    func test_combine_same_signal_all() {
        let e = expectation(description: "")

        let o = SourceObservable<Int>()
        let p = SourceObservable<Int>()
        let q = SourceObservable<Int>()
        let r = o.combine(with: p, q)

        o.next(3)
        p.next(2)
        q.next(1)

        var eventCounter = 3
        r.on(next: {
            eventCounter -= 1

            if eventCounter == 0 {
            XCTAssertEqual($0[0], 3)
            XCTAssertEqual($0[1], 2)
            XCTAssertEqual($0[2], 1)

            e.fulfill()
            }
        })

        wait(for: [e], timeout: 1)
    }

    func test_filter() {
        let e = expectation(description: "")

        let o = SourceObservable<Int>()
        let p = o.filter({ $0 % 2 == 0 })

        o.next(3)
        o.next(2)

        p.on(next: {
            XCTAssertEqual($0, 2)
            e.fulfill()
        })

        wait(for: [e], timeout: 1)
    }

    func test_compact_map() {
        let e = expectation(description: "")

        let o = SourceObservable<Int>()
        let p = o.compactMap({ $0 % 2 == 0 ? String($0) : nil })

        o.next(3)
        o.next(2)

        p.on(next: {
            XCTAssertEqual($0, "2")
            e.fulfill()
        })

        wait(for: [e], timeout: 1)
    }

    func test_map() {
        let e = expectation(description: "")

        let o = SourceObservable<Int>()
        let p = o.map({ String($0) })

        o.next(3)

        p.on(next: {
            XCTAssertEqual($0, "3")
            e.fulfill()
        })

        wait(for: [e], timeout: 1)
    }

    func test_skip() {
        let e = expectation(description: "")

        let o = SourceObservable<Int>()
        let p = o.skip(2)

        o.next(3)
        o.next(2)
        o.next(1)

        p.on(next: {
            XCTAssertEqual($0, 1)
            e.fulfill()
        })

        wait(for: [e], timeout: 1)
    }

}
