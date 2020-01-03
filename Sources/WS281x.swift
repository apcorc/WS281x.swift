/*
   WS281x.swift

   Copyright (c) 2017 Umberto Raimondi
   Licensed under the MIT license, as follows:

   Permission is hereby granted, free of charge, to any person obtaining a copy
   of this software and associated documentation files (the "Software"), to deal
   in the Software without restriction, including without limitation the rights
   to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
   copies of the Software, and to permit persons to whom the Software is
   furnished to do so, subject to the following conditions:

   The above copyright notice and this permission notice shall be included in all
   copies or substantial portions of the Software.

   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
   OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
   SOFTWARE.)
*/
import SwiftyGPIO  //Comment this when not using the package manager

public class WS281x {
    public let numElements: Int
    public let colorOrder: ColorOrder
    public var optimizedAnimationMode: Bool = false
    
    internal let type: WSKind
    internal let pwm: PWMOutput
    internal var sequence: [ByteConvertibleColor]

    public init(
        _ pwm: PWMOutput,
        type: WSKind,
        numElements: Int,
        order: ColorOrder = .RGB
    ) {
        self.pwm = pwm
        self.type = type
        self.numElements = numElements
        self.colorOrder = order

        sequence = [UInt32](repeating: 0x0, count: numElements)
        
        // Initialize PWM
        pwm.initPWM()
        pwm.initPWMPattern(bytes: numElements*3, 
                            at: type.frequency,
                            with: type.resetDelay,
                            dutyzero: type.zero,
                            dutyone: type.one)
    }

    /// Set a led using the sequence id
    public func setLed(_ id: Int, color: ByteConvertibleColor) {
        sequence[id] = color
    }

    /// Set a led in a sequence viewed as a classic matrix, where each row starts with an id = rownum*width.
    /// Used in some matrixes, es. Nulsom Rainbow Matrix.
    /// Es.
    ///  0  1  2  3
    ///  4  5  6  7
    ///  8  9  10 11
    ///  12 13 14 15
    ///
    public func setLedAsMatrix(point: MatrixPoint, width: Int, color: ByteConvertibleColor) {
        let position = (point.y * width) + point.x
        setLed(position, color: color)
    }

    /// Start transmission
    public func start() {
        pwm.sendDataWithPattern(values: toByteStream())
    }

    /// Wait for the transmission to end
    public func wait() {
        pwm.waitOnSendData()
    }

    /// Clean up once you are done
    public func cleanup() {
        pwm.cleanupPattern()
    }

    private func toByteStream() -> [UInt8]{
        var byteStream = [UInt8]()
        for led in sequence {
            let byte: UInt32
            
            // Bypass shifting colors that have been pre-optimized
            if let int32Color = led as? UInt32, optimizedAnimationMode {
                byte = int32Color
            } else {
                byte = led.toByte(order: self.colorOrder)
            }
            
            byteStream.append(UInt8((byte >> UInt32(16)) & 0xff))
            byteStream.append(UInt8((byte >> UInt32(8)) & 0xff))
            byteStream.append(UInt8(byte & 0xff))
        }
        return byteStream
    }
}

public struct WSKind {
    let zero: Int
    let one: Int
    let frequency: Int
    let resetDelay: Int
    
    public init(
        zero: Int,
        one: Int,
        frequency: Int,
        resetDelay: Int
    ) {
        self.zero = zero
        self.one = one
        self.frequency = frequency
        self.resetDelay = resetDelay
    }
    
    /// T0H:0.5us T0L:2.0us, T1H:1.2us T1L:1.3us , resDelay > 50us
    public static let WS2811 = WSKind(zero: 33, one: 66, frequency: 800_000, resetDelay: 55)
    
    /// T0H:0.35us T0L:0.8us, T1H:0.7us T1L:0.6us , resDelay > 50us
    public static let WS2812 = WSKind(zero: 33, one: 66, frequency: 800_000, resetDelay: 55)
    
    /// T0H:0.35us T0L:0.9us, T1H:0.9us T1L:0.35us , resDelay > 50us
    public static let WS2812B = WSKind(zero: 33, one: 66, frequency: 800_000, resetDelay: 55)
    
    /// T0H:0.35us T0L:0.9us, T1H:0.9us T1L:0.35us , resDelay > 300us 2017 revision of WS2812B
    public static let WS2812B2017 = WSKind(zero: 33, one: 66, frequency: 800_000, resetDelay: 300)
    
    /// T0H:0.4us T0L:0.84us, T1H:0.85us T1L:0.4us , resDelay > 50us
    public static let WS2812S = WSKind(zero: 33, one: 66, frequency: 800_000, resetDelay: 55)
    
    /// T0H:0.35us T0L:0.9us, T1H:0.9us T1L:0.35us , resDelay > 250us ?
    public static let WS2813 = WSKind(zero: 33, one: 66, frequency: 800_000, resetDelay: 255)
    
    /// T0H:0.25us T0L:0.6us, T1H:0.6us T1L:0.25us , resDelay > 280us ?
    public static let WS2813B = WSKind(zero: 30, one: 70, frequency: 800_000, resetDelay: 280)
}

public enum ColorOrder {
    case RGB
    case RBG
    case GRB
    case GBR
    case BRG
    case BGR
}

public protocol ByteConvertibleColor {
    func toByte(order: ColorOrder) -> UInt32
}

public struct WSRGBColor: ByteConvertibleColor {
    let red: UInt8
    let green: UInt8
    let blue: UInt8
    
    public init(
        red: UInt8,
        green: UInt8,
        blue: UInt8
    ) {
        self.red = red
        self.green = green
        self.blue = blue
    }
    
    public func toByte(order: ColorOrder) -> UInt32 {
        switch order {
        case .RGB: return (UInt32(red) << 16) | (UInt32(green) << 08) | (UInt32(blue) << 00)
        case .RBG: return (UInt32(red) << 16) | (UInt32(green) << 00) | (UInt32(blue) << 08)
        case .GRB: return (UInt32(red) << 08) | (UInt32(green) << 16) | (UInt32(blue) << 00)
        case .GBR: return (UInt32(red) << 00) | (UInt32(green) << 16) | (UInt32(blue) << 08)
        case .BRG: return (UInt32(red) << 08) | (UInt32(green) << 00) | (UInt32(blue) << 16)
        case .BGR: return (UInt32(red) << 00) | (UInt32(green) << 08) | (UInt32(blue) << 16)
        }
    }
}

public struct WSRGBAColor: ByteConvertibleColor {
    let red: UInt8
    let green: UInt8
    let blue: UInt8
    let alpha: UInt8
    
    public init(
        red: UInt8,
        green: UInt8,
        blue: UInt8,
        alpha: UInt8
    ) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }
    
    public func toByte(order: ColorOrder) -> UInt32 {
        let alphaScaling = alpha / 0xFF
        let red = self.red * alphaScaling
        let green = self.green * alphaScaling
        let blue = self.blue * alphaScaling
        
        switch order {
        case .RGB: return (UInt32(red) << 16) | (UInt32(green) << 08) | (UInt32(blue) << 00)
        case .RBG: return (UInt32(red) << 16) | (UInt32(green) << 00) | (UInt32(blue) << 08)
        case .GRB: return (UInt32(red) << 08) | (UInt32(green) << 16) | (UInt32(blue) << 00)
        case .GBR: return (UInt32(red) << 00) | (UInt32(green) << 16) | (UInt32(blue) << 08)
        case .BRG: return (UInt32(red) << 08) | (UInt32(green) << 00) | (UInt32(blue) << 16)
        case .BGR: return (UInt32(red) << 00) | (UInt32(green) << 08) | (UInt32(blue) << 16)
        }
    }
}

extension UInt32: ByteConvertibleColor {
    public func toByte(order: ColorOrder) -> UInt32 {
        let red = UInt8((self >> UInt32(16)) & 0xff)
        let green = UInt8((self >> UInt32(8)) & 0xff)
        let blue = UInt8(self & 0xff)
        
        switch order {
        case .RGB: return (UInt32(red) << 16) | (UInt32(green) << 08) | (UInt32(blue) << 00)
        case .RBG: return (UInt32(red) << 16) | (UInt32(green) << 00) | (UInt32(blue) << 08)
        case .GRB: return (UInt32(red) << 08) | (UInt32(green) << 16) | (UInt32(blue) << 00)
        case .GBR: return (UInt32(red) << 00) | (UInt32(green) << 16) | (UInt32(blue) << 08)
        case .BRG: return (UInt32(red) << 08) | (UInt32(green) << 00) | (UInt32(blue) << 16)
        case .BGR: return (UInt32(red) << 00) | (UInt32(green) << 08) | (UInt32(blue) << 16)
        }
    }
}

public struct MatrixPoint {
    public let x: Int
    public let y: Int
    
    public init(x: Int, y: Int) {
        self.x = x
        self.y = y
    }
}
