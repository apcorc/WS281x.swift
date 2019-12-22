//
//  WS281xTests.swift
//  
//  Created by Alex Corcoran on 12/21/19.
//

import Foundation
import XCTest

import SwiftyGPIO
@testable import WS281x

final class WS281xTests: XCTestCase {
    
    override var continueAfterFailure: Bool {
        get { return true }
        set { }
    }

    let red = WSRGBColor(red: 0xFF, green: 0x0, blue: 0x0)
    let green = WSRGBColor(red: 0x0, green: 0xFF, blue: 0x0)
    let blue = WSRGBColor(red: 0x0, green: 0x0, blue: 0xFF)
    
    override class func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testColorOrderRGB() {
        let order = ColorOrder.RGB
        
        XCTAssertEqual(red.toByte(order: order), 0xFF0000)
        XCTAssertEqual(green.toByte(order: order), 0x00FF00)
        XCTAssertEqual(blue.toByte(order: order), 0x0000FF)
    }
    
    func testColorOrderRBG() {
        let order = ColorOrder.RBG
        
        XCTAssertEqual(red.toByte(order: order), 0xFF0000)
        XCTAssertEqual(green.toByte(order: order), 0x0000FF)
        XCTAssertEqual(blue.toByte(order: order), 0x00FF00)
    }
    
    func testColorOrderGRB() {
        let order = ColorOrder.GRB
        
        XCTAssertEqual(red.toByte(order: order), 0x00FF00)
        XCTAssertEqual(green.toByte(order: order), 0xFF0000)
        XCTAssertEqual(blue.toByte(order: order), 0x0000FF)
    }
    
    func testColorOrderGBR() {
        let order = ColorOrder.GBR
        
        XCTAssertEqual(red.toByte(order: order), 0x0000FF)
        XCTAssertEqual(green.toByte(order: order), 0xFF0000)
        XCTAssertEqual(blue.toByte(order: order), 0x00FF00)
    }
    
    func testColorOrderBRG() {
        let order = ColorOrder.BRG
        
        XCTAssertEqual(red.toByte(order: order), 0x00FF00)
        XCTAssertEqual(green.toByte(order: order), 0x0000FF)
        XCTAssertEqual(blue.toByte(order: order), 0xFF0000)
    }
    
    func testColorOrderBGR() {
        let order = ColorOrder.BGR
        
        XCTAssertEqual(red.toByte(order: order), 0x0000FF)
        XCTAssertEqual(green.toByte(order: order), 0x00FF00)
        XCTAssertEqual(blue.toByte(order: order), 0xFF0000)
    }
    
    func testMatrixPoint() {
        let point = MatrixPoint(x: 2, y: 4)
        
        XCTAssertEqual(point.x, 2)
        XCTAssertEqual(point.y, 4)
    }
    
    func testWS281xInit() {
        let pwm = MockPWM()

        let numberOfLeds = 50
        let w = WS281x(pwm, type: .WS2811, numElements: numberOfLeds)
        
        let shouldBeTrue = [
            pwm.initPWMCalled,
            pwm.initPWMPatternCalled,
        ]
        
        let shouldBeFalse = [
            pwm.startPWMCalled,
            pwm.stopPWMCalled,
            pwm.sendDataWithPatternCalled,
            pwm.waitOnSendDataCalled,
            pwm.cleanupPatternCalled,
        ]
        
        XCTAssertAllTrue(shouldBeTrue)
        XCTAssertAllFalse(shouldBeFalse)
        XCTAssertNil(pwm.lastSendDataPattern)
        
        XCTAssertEqual(w.numElements, 50)
    }
    
    func testUInt32ToByte() {
        let int32: UInt32 = 0x0
        XCTAssertEqual(int32.toByte(order: .RGB), 0x000000)
    }
    
    func testSetLED() {
        let pwm = MockPWM()
        let numberOfLeds = 10
        let w = WS281x(pwm, type: .WS2811, numElements: numberOfLeds)
        
        w.setLed(5, color: WSRGBColor(red: 0xFF, green: 0x00, blue: 0x00))
        
        let expectedSequence: [UInt32] = [
            0x0, // Index 0
            0x0,
            0x0,
            0x0,
            0x0,
            0xFF0000, // Index 5
            0x0,
            0x0,
            0x0,
            0x0, // Index 9
        ]
        
        let bytes = w.sequence.map { $0.toByte(order: .RGB) }
        
        XCTAssertEqual(bytes, expectedSequence)
    }
    
    func testSetLEDAsMatrix() {
//
//        4 x 4 matrix (16 LEDs):
//        COLUMN:
//        0-, 1-, 2-, 3-
//
//        00, 01, 02, 03,   // Row 0
//        04, 05, 06, 07,   // Row 1
//        08, 09, 10, 11,   // Row 2
//        12, 13, 14, 15    // Row 3
//
        let pwm = MockPWM()
        let numberOfLeds = 16
        let w = WS281x(pwm, type: .WS2811, numElements: numberOfLeds)
        
        let color = WSRGBColor(red: 0xFF, green: 0x00, blue: 0x00)
        // Point from 0-based index: Column 1, Row 2 -- LED index 9
        w.setLedAsMatrix(point: MatrixPoint(x: 1, y: 2), width: 4, color: color)
        
        let expectedSequence: [UInt32] = [
            0x0, 0x000000, 0x0, 0x0,
            0x0, 0x000000, 0x0, 0x0,
            0x0, 0xFF0000, 0x0, 0x0,
            0x0, 0x000000, 0x0, 0x0,
        ]
        
        let bytes = w.sequence.map { $0.toByte(order: .RGB) }
        
        XCTAssertEqual(bytes, expectedSequence)
    }
    
    func testWait() {
        let pwm = MockPWM()
        let numberOfLeds = 16
        let w = WS281x(pwm, type: .WS2811, numElements: numberOfLeds)
        
        XCTAssertFalse(pwm.waitOnSendDataCalled)
        w.wait()
        XCTAssertTrue(pwm.waitOnSendDataCalled)
    }
    
    func testCleanup() {
        let pwm = MockPWM()
        let numberOfLeds = 16
        let w = WS281x(pwm, type: .WS2811, numElements: numberOfLeds)
        
        XCTAssertFalse(pwm.cleanupPatternCalled)
        w.cleanup()
        XCTAssertTrue(pwm.cleanupPatternCalled)
    }
    
    func testStart_RGB() {
        let pwm = MockPWM()
        let numberOfLeds = 10
        let w = WS281x(pwm, type: .WS2811, numElements: numberOfLeds)
        
        w.setLed(5, color: WSRGBColor(red: 0xFF, green: 0x00, blue: 0x00))
        
        let expectedSequence: [UInt8] = [
//          R     G     B
            0x00, 0x00, 0x00, // Index 0
            0x00, 0x00, 0x00,
            0x00, 0x00, 0x00,
            0x00, 0x00, 0x00,
            0x00, 0x00, 0x00,
            0xFF, 0x00, 0x00, // Index 5
            0x00, 0x00, 0x00,
            0x00, 0x00, 0x00,
            0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, // Index 9
        ]
        
        w.start()
        
        XCTAssertEqual(pwm.lastSendDataPattern, expectedSequence)
    }
    
    func testStart_GRB() {
        let pwm = MockPWM()
        let numberOfLeds = 10
        let w = WS281x(pwm, type: .WS2811, numElements: numberOfLeds, order: .GRB)
        
        w.setLed(5, color: WSRGBColor(red: 0xFF, green: 0x00, blue: 0x00))
        
        let expectedSequence: [UInt8] = [
//          G     R     B
            0x00, 0x00, 0x00, // Index 0
            0x00, 0x00, 0x00,
            0x00, 0x00, 0x00,
            0x00, 0x00, 0x00,
            0x00, 0x00, 0x00,
            0x00, 0xFF, 0x00, // Index 5
            0x00, 0x00, 0x00,
            0x00, 0x00, 0x00,
            0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, // Index 9
        ]
        
        w.start()
        
        XCTAssertEqual(pwm.lastSendDataPattern, expectedSequence)
    }
}

private final class MockPWM: PWMOutput {
    var initPWMCalled = false
    var startPWMCalled = false
    var stopPWMCalled = false
    var initPWMPatternCalled = false
    var sendDataWithPatternCalled = false
    var waitOnSendDataCalled = false
    var cleanupPatternCalled = false
    var lastSendDataPattern : [UInt8]? = nil
    
    func initPWM() {
        initPWMCalled = true
    }
    
    func startPWM(period ns: Int, duty percent: Float) {
        startPWMCalled = true
    }
    
    func stopPWM() {
        stopPWMCalled = true
    }
    
    func initPWMPattern(
        bytes count: Int,
        at frequency: Int,
        with resetDelay: Int,
        dutyzero: Int,
        dutyone: Int
    ) {
        initPWMPatternCalled = true
    }
    
    func sendDataWithPattern(values: [UInt8]) {
        lastSendDataPattern = values
    }
    
    func waitOnSendData() {
        waitOnSendDataCalled = true
    }
    
    func cleanupPattern() {
        cleanupPatternCalled = true
    }
}
