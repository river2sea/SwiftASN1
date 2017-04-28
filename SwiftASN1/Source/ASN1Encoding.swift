//
//  DERBuilder.swift
//  PeaceKeeper
//
//  Created by Rowland Smith on 11/11/15.
//  Copyright © 2015 River2Sea. All rights reserved.
//

/* Bit Twiddling Notes

    Clearing A Bit:

        let clearBit = 31
        tag &= ~( 1 << clearBit )
*/


// swiftlint:disable force_cast

import Foundation


fileprivate func < <T: Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func > <T: Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


// MARK: Encoding & Decoding

public protocol ASN1Encoder {

    var data: Data { get set }

    func encodeInteger( value: Integer, meta: ASN1Meta ) throws
    func encodeBoolean( value: Boolean, meta: ASN1Meta ) throws
    func encodeIA5String( value: IA5String, meta: ASN1Meta ) throws
    func encodePrintableString( value: PrintableString, meta: ASN1Meta ) throws
    func encodeUTF8String( value: UTF8String, meta: ASN1Meta ) throws
    func encodeObjectIdentifier( value: ObjectIdentifier, meta: ASN1Meta ) throws
    func encodeBitString( value: BitString, meta: ASN1Meta ) throws
    func encodeOctetString( value: OctetString, meta: ASN1Meta ) throws
    func encodeSequence( value: Sequence, meta: ASN1Meta ) throws
    func encodeSequenceOf( value: SequenceOf, meta: ASN1Meta ) throws
    func encodeSet( value: Set, meta: ASN1Meta ) throws
    func encodeSetOf( value: SetOf, meta: ASN1Meta ) throws
    func encodeChoice( value: Choice, meta: ASN1Meta ) throws
    func encodeNull( value: Null, meta: ASN1Meta ) throws
    func encodeASN1Any( value: ASN1Any, meta: ASN1Meta ) throws

}

public enum DEREncoderError: Error {

    case unknownTypeError( value : ASN1Type )
    case emptyAnyValue()
    case emptyChoiceValue()
    case longFormNotSupported

}

/* Why was this ever put here? -rds
extension Array {
    subscript(i: UInt) -> Element {
        get {
            return self[Int(i)]
        } set(from) {
            self[Int(i)] = from
        }
    }
}
*/

public class DEREncoder {

    public var data: Data
    fileprivate var currentLength: Int
    fileprivate var XcurrentField: MetaField?
    fileprivate var fieldIsConstructed: Bool
    fileprivate var vlqEncoder: VLQEncoder
    public var isLogging: Bool

    public init( data: Data ) {
        self.data = data
        self.currentLength = 0
        self.fieldIsConstructed = false
        self.isLogging = true
        
        self.vlqEncoder = VLQEncoder()
    }

    public func encode( value: ASN1Type ) throws {

        log( message: "Encoding Top Level ASN1 Value: \(value):" )

        let meta = ASN1Meta( tagClass: .universal, tagNumber: value.DefaultTag )

        switch value {
            
            case let value as Integer:
                try encodeInteger( value: value, meta: meta )

            case let value as Boolean:
                try encodeBoolean( value: value, meta: meta )

            case let value as IA5String:
                try encodeIA5String( value: value, meta: meta )

            case let value as PrintableString:
                try encodePrintableString( value: value, meta: meta )

            case let value as UTF8String:
                try encodeUTF8String( value: value, meta: meta )

            case let value as BitString:
                try encodeBitString( value: value, meta: meta )

            case let value as OctetString:
                try encodeOctetString( value: value, meta: meta )

            case let value as ObjectIdentifier:
                try encodeObjectIdentifier( value: value, meta: meta )

            case let value as Sequence:
                try encodeSequence( value: value, meta: meta )

            case let value as SequenceOf:
                try encodeSequenceOf( value: value, meta: meta )

            case let value as Set:
                try encodeSet( value: value, meta: meta )

            case let value as SetOf:
                try encodeSetOf( value: value, meta: meta )

            case let value as Choice:
               try encodeChoice( value: value, meta: meta )

            case let value as Null:
                try encodeNull( value: value, meta: meta )

            case let value as ASN1Any:
               try encodeASN1Any( value: value, meta: meta )

            default:
                throw DEREncoderError.unknownTypeError( value: value )

        }

    }

    public func encodeTagAndLength( tagNumber: Int, tagClass: TagClass, length: Int, constructed: Bool = false ) throws {

        // Use of DefaultTag should be resolved before calling this method. -rds
        
        log( message: "tagNumber=\(tagNumber) : tagClass=\(tagClass) : length=\(length) : constructed=\(constructed)" )
        
        try encodeTag( tagNumber: tagNumber, tagClass: tagClass, constructed: constructed )
        encodeLength( length: length )

    }

    public func encodeTag( tagNumber: Int, tagClass: TagClass, constructed: Bool = false ) throws {

        var octet: Int = 0
        
        // CRASH
 
        if tagNumber < 32 {
            octet = tagNumber | tagClass.rawValue
        } else {
            throw DEREncoderError.longFormNotSupported
            // Long Form tag is not supported.
        }

        if constructed {
            octet = octet | 0x20
        }

        var param = UInt8( octet )
        //print( octet )
        data.append( &param, count: 1 )

    }

    public func encodeLength( length: Int ) {

        assert( length < 0x8000 )

        if length < 128 {

            currentLength = 1
            var d: UInt8 = UInt8( length )
            data.append( &d, count: currentLength )

        } else if length < 0x100 {

            currentLength = 2
            var d : [ UInt8 ] = [ 0x81, UInt8( length & 0xFF ) ]
            data.append( &d, count: currentLength )

        } else if length < 0x8000 {

            currentLength = 3
            var d : [ UInt8 ] = [ 0x82, UInt8( ( length & 0xFF00 ) >> 8 ), UInt8( length & 0xFF ) ]
            data.append( &d, count: currentLength )

        }

    }

    fileprivate func log( message: String ) {
        if isLogging {
            NSLog( message )
        }
    }

}


extension DEREncoder : ASN1Encoder {

    public func encodeInteger( value: Integer, meta: ASN1Meta ) throws {

        var intValue = value.value

        var bytes = Array<UInt8>( repeating: 0, count: 8 )

        if intValue >= 0 && intValue <= 1 {
            try encodeTagAndLength( tagNumber: meta.tagNumber, tagClass: meta.tagClass, length: 1 )
            data.append( [ UInt8( intValue ) ], count: 1 )
            return
        }

        bytes = Array<UInt8>( repeating: 0, count: 8 )
        memcpy( &bytes, &intValue, 8 )
        var length = numBytesUsed( n: UInt64( intValue ) )

        if length < 8 {
            //let toShift = ( UInt64( 8 ) - UInt64( length ) ) * UInt64( 8 )
            bytes = Array<UInt8>( bytes.reversed()[ ( 8 - length )...7 ] )
        }

        try encodeTagAndLength( tagNumber: meta.tagNumber, tagClass: meta.tagClass, length: length )

        if intValue < 0 {
            // Encode as negative...
        } else {
            // If the high bit is 1, insert a 0x00 byte to force the value to be positive.
            //
            if 0x80 & bytes[ 0 ] == 0x80 {
                length += 1
                data.append( [ UInt8( 0 ) ], count: 1 )
            }
        }

        data.append( bytes, count: bytes.count )

    }

    fileprivate func numBytesUsed( n: UInt64 ) -> Int {

        let usedBits = 64 - VLQEncoder.numberOfLeadingZeros( value: n )
        var usedBytes = usedBits / 8
        let remainder = usedBits % 8

        if remainder > 0 {
            usedBytes += 1
        }

        return Int( usedBytes )

    }

    public func encodeBoolean( value: Boolean, meta: ASN1Meta ) throws {
        try encodeTagAndLength( tagNumber: meta.tagNumber, tagClass: meta.tagClass, length: 1 )
        let octet: [ UInt8 ] =  value.value ? [ 0xFF ] : [ 0x00 ]
        data.append( octet, count: 1 )
    }

    public func encodeIA5String( value: IA5String, meta: ASN1Meta ) throws {
        let buffer = [ UInt8 ]( value.value.utf8 )
        try encodeTagAndLength( tagNumber: meta.tagNumber, tagClass: meta.tagClass, length: buffer.count )
        data.append( buffer, count: buffer.count )
    }

    public func encodePrintableString( value: PrintableString, meta: ASN1Meta ) throws {
        let buffer = [ UInt8 ]( value.value.utf8 )
        try encodeTagAndLength( tagNumber: meta.tagNumber, tagClass: meta.tagClass, length:buffer.count )
        data.append( buffer, count:buffer.count )
    }

    public func encodeUTF8String( value: UTF8String, meta: ASN1Meta ) throws {
        let buffer = [ UInt8 ]( value.value.utf8 )
        try encodeTagAndLength( tagNumber: meta.tagNumber, tagClass: meta.tagClass, length:buffer.count )
        data.append( buffer, count:buffer.count )
    }

    public func encodeObjectIdentifier( value: ObjectIdentifier, meta: ASN1Meta ) throws {

        var length = 0
        var buffer = Data( capacity:128 )

        let firstOctet = UInt8( ( value.value[ 0 ] * 40 ) + value.value[ 1 ] )
        length += 1

        let components = value.value[ 2...value.value.count - 1 ]

        for component: UInt32 in components {
            let encoding = vlqEncoder.encode( value: component )
            buffer.append( encoding, count:encoding.count )
            length += encoding.count
        }

        try encodeTagAndLength( tagNumber: meta.tagNumber, tagClass: meta.tagClass, length:length )
        data.append( [ firstOctet ], count:1 )
        data.append( buffer )

    }

    public func encodeBitString( value: BitString, meta: ASN1Meta ) throws {
        // Add 1 to the length to account for the unused-bits octet.
        try encodeTagAndLength( tagNumber: meta.tagNumber, tagClass: meta.tagClass, length:value.value!.count + 1 )
        data.append( &value.unusedBits, count:1 )
        data.append( value.value! )
    }

    public func encodeOctetString( value: OctetString, meta: ASN1Meta ) throws {
        try encodeTagAndLength( tagNumber: meta.tagNumber, tagClass: meta.tagClass, length: value.value!.count )
        data.append( value.value! )
    }

    // swiftlint:disable function_body_length
    // swiftlint:disable cyclomatic_complexity

    public func encodeSequence( value: Sequence, meta: ASN1Meta ) throws {

        // Encode this Sequence into a buffer, then append that buffer 
        // to the 'real' buffer. This way we can get the length.

        let oldData = self.data
        self.data = Data( capacity: 4096 )
        var implicitTag = 0

        // FUTURE: Set the tag of a value that is a Field to the implicitTag
        //       Unless Field defines an explicitTag, then use the explicitTag...

        log( message: "Encoding Sequence: \(value):" )

        // FUTURE: Handle OPTIONAL fields.

        for field in value.fields {

            //currentField = field

            log( message: "  Encoding Field: \(field.debugDescription)" )

            if field.optional && field.value == nil {
                continue
            } else if !field.optional && field.value == nil {
                throw ASN1ModelError.requiredFieldAbsentError( name: field.name )
            }

            // Encapsulate the value in an OCTET STRING.
            //
            if field.value!.encodingDirective == .octetString {
                log( message: "Encapsulating value as OCTET STRING" )
                let encoder = DEREncoder( data: Data() )
                try encoder.encode( value: field.value! )
                let buffer = encoder.data
                print( "buffer: \(buffer.hexString() )" )
                // CRASH: Is this the right 'meta' to pass here? -rds
                // TODO: use the buffer's bytes - hexString is very inefficient. -rds
                try encodeOctetString( value: OctetString( hex: buffer.hexString() ), meta: meta )
                continue
            }
            
            switch field.value {
                
                case let fieldValue as Integer:
                    try encodeInteger( value: fieldValue, meta: field )

                case let fieldValue as Boolean:
                    try encodeBoolean( value: fieldValue, meta: field )

                case let fieldValue as IA5String:
                    try encodeIA5String( value: fieldValue, meta: field )

                case let fieldValue as PrintableString:
                    try encodePrintableString( value: fieldValue, meta: field )

                case let fieldValue as UTF8String:
                    try encodeUTF8String( value: fieldValue, meta: field )

                case let fieldValue as BitString:
                    try encodeBitString( value: fieldValue, meta: field )

                case let fieldValue as OctetString:
                    try encodeOctetString( value: fieldValue, meta: field )

                case let fieldValue as ObjectIdentifier:
                    try encodeObjectIdentifier( value: fieldValue, meta: field )

                case let fieldValue as Sequence:
                    try encodeSequence( value: fieldValue, meta: field )

                case let fieldValue as SequenceOf:
                    try encodeSequenceOf( value:fieldValue, meta: field )

                case let fieldValue as Set:
                    try encodeSet( value:fieldValue, meta: field )

                case let fieldValue as SetOf:
                    try encodeSetOf( value:fieldValue, meta: field )

                case let fieldValue as Choice:
                    try encodeChoice( value: fieldValue, meta: field )

                case let fieldValue as Null:
                    try encodeNull( value: fieldValue, meta: field )

                case let fieldValue as ASN1Any:
                    try encodeASN1Any( value: fieldValue, meta: field )

                default:
                    throw DEREncoderError.unknownTypeError( value: field.value! )
            }

            implicitTag += 1

        }

        let tmpData = self.data
        self.data = oldData
        
        try encodeTagAndLength( tagNumber: meta.tagNumber, tagClass: meta.tagClass, length: tmpData.count, constructed: true )
        
        //data.append( tmpData )
        appendData( other: tmpData )
    }
    
    // swiftlint:enable function_body_length
    // swiftlint:disable cyclomatic_complexity

    public func encodeSequenceOf( value: SequenceOf, meta: ASN1Meta ) throws {

        if value.elements.isEmpty {
            return
        }

        // Create a new buffer and swap with self.data...

        let oldData = self.data
        self.data = Data()

        try value.elements.forEach { element in
            try encode( value: element )
        }

        let tmpData = data
        self.data = oldData
        try encodeTagAndLength( tagNumber: meta.tagNumber, tagClass: meta.tagClass, length: tmpData.count, constructed: true )
        self.data.append( tmpData )

    }

    /**
     Not Implemented.
     */
    public func encodeSet( value: Set, meta: ASN1Meta ) throws { abort() }

    /**
     This encoder assumes that the elements of the SetOf 'value' have been
     placed in the collection in sorted order as specified by the DER (X.690).
     */
    public func encodeSetOf( value: SetOf, meta: ASN1Meta ) throws {

        if value.elements.isEmpty {
            return
        }

        // Create a new buffer and swap with self.data...

        let oldData = data
        data = Data()

        try value.elements.forEach { element in
            try encode( value: element )
        }

        // Swap oldData with data and append oldData to data.
        
        let tmpData = data
        data = oldData
        try encodeTagAndLength( tagNumber: meta.tagNumber, tagClass: meta.tagClass, length:tmpData.count, constructed:true )
        data.append( tmpData )

    }

    private func appendData( other: Data ) {
        //logDebug( other.hexString() )
        data.append( other )
    }
    
    public func encodeChoice( value: Choice, meta: ASN1Meta ) throws {

        if let chosen = value.chosen {
            // CRASH: The meta data isn't being passd on here. -rds
            try encode( value: chosen )
        } else {
            // The current design does not allow an empty CHOICE. -rds
        }

    }

    public func encodeNull( value: Null, meta: ASN1Meta ) throws {
        //try encodeTagAndLength( tagNumber: meta.tagNumber, tagClass: meta.tagClass, length: 1 )
        try encodeTag( tagNumber: meta.tagNumber, tagClass: meta.tagClass )
        let byte: [ UInt8 ] = [ 0 ]
        data.append( byte, count: 1 )
    }

    public func encodeASN1Any( value: ASN1Any, meta: ASN1Meta ) throws {

        if let concreteValue = value.value {
            try encode( value: concreteValue )
        }
        
        /*
        switch value.encodingDirective {

            case .standard:
                if let concreteValue = value.value {
                    try encode( value: concreteValue )
                }
            
            case .octetString:
                
                if value.value! is ASN1Any {
                    print( "blah" )
                }
                log( message: "Encapsulating ANY value as OCTET STRING" )
                var anyBuffer = Data()
                let oldData = data
                data = anyBuffer
                try encode( value: value.value! )
                anyBuffer = data
                data = oldData
                print( "anyBuffer: \(anyBuffer.hexString() )" )
                // CRASH: Is this the right 'meta' to pass here? -rds
                try encodeOctetString( value: OctetString( hex: anyBuffer.hexString() ), meta: meta )
            
        }
        */
    }

}
