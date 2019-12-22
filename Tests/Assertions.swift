//
//  Assertions.swift
//
//  Created by Alex Corcoran on 12/21/19.
//

import XCTest

public func XCTAssertAllTrue(
    _ expression: @autoclosure () throws -> [Bool],
    _ message: @autoclosure () -> String = "",
    file: StaticString = #file,
    line: UInt = #line
) {
    do {
        let array = try expression()
        let result = array.reduce(true) { return $0 && $1 }
        XCTAssertTrue(result, message(), file: file, line: line)
    } catch _ {
        XCTFail(message(), file: file, line: line)
    }
}

public func XCTAssertAllFalse(
    _ expression: @autoclosure () throws -> [Bool],
    _ message: @autoclosure () -> String = "",
    file: StaticString = #file,
    line: UInt = #line
) {
    do {
        let array = try expression()
        let result = array.reduce(false) { return $0 || $1 }
        XCTAssertFalse(result, message(), file: file, line: line)
    } catch _ {
        XCTFail(message(), file: file, line: line)
    }
}
