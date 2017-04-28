//
//  NSData+HexString.swift
//  Cybertk
//
//  Created by Quanlong He on 8/14/15.
//  Copyright © 2015 Quanlong He. All rights reserved.
//

import Foundation

private let kHexChars = Array("0123456789ABCDEF".utf8) as [UInt8]

/*
extension NSData {

    public func toHexString() -> String {

        var hexString: String = ""
        let dataBytes =  UnsafePointer<CUnsignedChar>(self.bytes)

        for (var i: Int=0; i<self.length; ++i) {
            hexString +=  String(format: "%02X", dataBytes[i])
        }

        return hexString
    }

}
*/

extension Data {

    public static func dataFromHex( _ hex: String ) -> Data? {
        let length = hex.characters.count


        let rawData = UnsafeMutablePointer<CUnsignedChar>.allocate( capacity: length/2)
        var rawIndex = 0

        for index in stride( from: 0, to:length, by:2 ) {
        //for var index = 0; index < length; index+=2{
            let single = NSMutableString()
            let range = (hex.characters.index(hex.startIndex, offsetBy: index) ..< hex.characters.index(hex.startIndex, offsetBy: index+2))
            single.append( hex.substring( with: range ) )
            rawData[ rawIndex ] = UInt8( single as String, radix:16 )!
            rawIndex += 1
        }

        let data: Data = Data( bytes: UnsafePointer<UInt8>(rawData), count: length/2 )
        rawData.deallocate( capacity: length/2 )
        return data
    }

    public func hexString() -> String {

        guard !isEmpty else {
            return ""
        }

        var buffer = [ UInt8 ]( repeating: 0, count: count )
        (self as NSData).getBytes( &buffer, length:count )
//        let buffer = UnsafeBufferPointer<UInt8>(start: UnsafePointer(bytes), count: length)
        var output = [UInt8]( repeating: 0, count: count * 2 + 1 )
        var i: Int = 0
        for b in buffer {
            let h = Int((b & 0xf0) >> 4)
            let l = Int(b & 0x0f)
            output[ i ] = kHexChars[h]
            i += 1
            output[ i ] = kHexChars[l]
            i += 1
        }

        return String(cString: UnsafePointer(output))
    }

    public func binaryString() -> String {

        let mask: UInt8 = 0x01

        var str = String( stringLiteral:"0          1          2           3\n01234567 89012345 67890123 45678901\n-----------------------------------\n" )

        let length = self.count
        var bytes = Array<UInt8>(repeating: 0, count: length )
        (self as NSData).getBytes( &bytes, length:length )

        //var offset : Int = 0
        for offset in 0..<length {
        //for ( offset = 0 ; offset < length ; offset += 1 ) {

            if offset > 0 {
                if offset % 4 == 0 {
                    str += "\n"
                } else {
                    str += " "
                }
            }

            //var bit = 7

            for bit in ( 0...7 ).reversed() {
            //for ( bit = 7 ; bit >= 0 ; bit-- ) {

                let byteMask: UInt8 = ( mask << UInt8( bit ) )
                let byte = bytes[ offset ]

                if byteMask & byte == byteMask {
                    str += "1"
                } else {
                    str += "0"
                }
            }

        }

        return String( stringLiteral:str )

    }

}
