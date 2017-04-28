//
//  ASN1.swift
//  PeaceKeeper
//
//  Created by Rowland Smith on 11/17/15.
//  Copyright © 2015 River2Sea. All rights reserved.
//

// swiftlint:disable force_cast


import Foundation


// swiftlint:disable cyclomatic_complexity
// swiftlint:disable function_body_length


public enum ASN1ModelError: Error {

    case unknownTypeError( value: ASN1Type )
    case fieldNotFoundError( name: String )
    case requiredFieldAbsentError( name: String )

}


public enum TagClass: Int {
    
    case universal          = 0x00
    case application        = 0x40
    case contextSpecific    = 0x80
    case `private`          = 0xC0
    
}


public enum EncodingDirective: Int {
    
    case standard = 0x00
    case octetString = 0x02
    
}


public protocol ASN1Container {}


public class Module: ASN1Container {

    var topLevelValues : [ ASN1Type ] = []

    public func calculateLength( tag: Int, dataLength: Int ) -> Int {
        // TODO: Implement or remove. -rds
        abort()
    }

}


public class ASN1Type {

    private(set) var DefaultTag: Int = -1

    public var encodingDirective: EncodingDirective = .standard

    init() {
    
    }

}


public class ASN1Any: ASN1Type {

    public var value: ASN1Type?

    public init( value: ASN1Type? ) {
        self.value = value
        super.init()
    }

    public override convenience init() {
        self.init( value:nil )
    }

}


//public class AnyAsOctetString : Field {}

/**
    TODO: Support arbitrary sized integers.
*/
public class Integer: ASN1Type {

    public override var DefaultTag: Int { return 2 }

    public let value: Int

    public init( value: Int ) {
        self.value = value
        super.init()
    }

}


public class Boolean: ASN1Type {

    public override var DefaultTag: Int { return 1 }

    public let value: Bool

    public init( value: Bool ) {
        self.value = value
        super.init()
    }

}


public class PrintableString: ASN1Type {

    public override var DefaultTag: Int { return 19 }

    public let value: String

    public init( value: String ) {
        self.value = value
        super.init()
    }

}


public class IA5String: ASN1Type {

    public override var DefaultTag: Int { return 22 }

    public let value: String

    public init( value: String ) {
        self.value = value
        super.init()
    }

}


public class UTF8String: ASN1Type {

    public override var DefaultTag: Int { return 12 }

    public let value: String

    public init( value: String ) {
        self.value = value
        super.init()
    }

}


// Optimize this...
//
public class ByteArray: ASN1Type {

    public var value: Data?

    public init( bytes : [ UInt8 ] ) {
        self.value = Data( bytes: UnsafePointer<UInt8>(bytes as [ UInt8 ]), count:bytes.count )
        super.init()
    }

    public init( hex: String ) {
        self.value = Data.dataFromHex( hex )
        super.init()
    }

    public init( data: Data ) {
        self.value = data
        super.init()
    }

}


public class BitString: ByteArray {

    public override var DefaultTag: Int { return 3 }

    public var unusedBits: UInt8 = 0

    public override init( bytes : [ UInt8 ] ) {
        super.init( bytes:bytes )
    }

    public override init( hex: String ) {
        super.init( hex:hex )
    }

    public override init( data: Data ) {
        super.init( data:data )
    }

}


public class OctetString: ByteArray {

    public override var DefaultTag: Int { return 4 }

    public override init( bytes : [ UInt8 ] ) {
        super.init( bytes:bytes )
    }

    public override init( hex: String ) {
        super.init( hex:hex )
    }

}


public func == ( lhs: ObjectIdentifier, rhs: ObjectIdentifier ) -> Bool {
    return lhs.value == rhs.value
}


public class ObjectIdentifier: ASN1Type, Hashable {

    public override var DefaultTag: Int { return 6 }

    public var value : [ UInt32 ]


    public var hashValue: Int {

        // DJB Hash Function

        var hash = 5381

        for i in 0..<value.count {
            hash = ( ( hash << 5 ) &+ hash) &+ Int( self.value[ i ] )
        }

        return hash

    }

    public init( value : [ UInt32 ] ) {
        self.value = value
        super.init()
    }

    public convenience init( string: String ) {
        let components = string.components( separatedBy: "." ).map { UInt32( $0 )! }
        self.init( value:components )
    }

    public convenience override init() {
        self.init( value : [] )
    }

}


public class ASN1Meta {
    
    public let tagClass: TagClass
    public var tagNumber: Int
    
    init( tagClass: TagClass, tagNumber: Int ) {
        self.tagClass = tagClass
        self.tagNumber = tagNumber
    }
    
    public var tagWithClass: Int {
        return tagNumber | tagClass.rawValue
    }
    
}


public class MetaField: ASN1Meta {
    
    public let name: String
    public var value: ASN1Type?
    public let optional: Bool
    
    init( name: String, value: ASN1Type?, tagClass: TagClass = .universal, tagNumber: Int = -1, optional: Bool = false ) {
        self.name = name
        self.value = value
        self.optional = optional
        var tag = tagNumber
        if tagNumber == -1 {
            tag = value!.DefaultTag
        }
        super.init( tagClass: tagClass, tagNumber: tag )
    }
    
    public var description: String { return "[ name:\(name), value:\(String(describing: value)), tagClass:\(tagClass), tagNumber:\(tagNumber), optional:\(optional) ]" }
    
    public var debugDescription: String { return description }
    
}


public class MetaElement: ASN1Meta {
    
    var value: ASN1Type?
    var optional: Bool
    
    init( value: ASN1Type?, tagClass: TagClass = .universal, tagNumber: Int = -1, optional: Bool = false ) {
        self.value = value
        self.optional = optional
        var tag = tagNumber
        if tagNumber == -1 {
            tag = value!.DefaultTag
        }
        super.init( tagClass: tagClass, tagNumber: tag )
    }
    
    public var description: String { return "[ value:\(String(describing: value)), tagClass:\(tagClass), tagNumber:\(tagNumber), optional:\(optional) ]" }
    
    public var debugDescription: String { return description }
    
}


/**
 Value must be encoded as an OCTET STRING.

public class OctetHoleField : Field {

    init( name: String, value : ASN1Any?, tagClass : TagClass, tag : Int, optional : Bool ) {
        super.init( name:name, value:value, tagClass:tagClass, tag:tag, optional:optional )
    }

}
*/

public class Sequence: ASN1Type, ASN1Container {

    public override var DefaultTag: Int { return 16 }

    var mutableFields = [ MetaField ]()

    public var fields : [ MetaField ] { return [ MetaField ]( mutableFields ) }

    public override init() {
        super.init()
    }

    internal func registerField( field: MetaField ) {
        mutableFields.append( field )
    }

    internal func registerField( name: String, value: ASN1Type?, tagClass: TagClass = .universal, tagNumber: Int = -1, optional: Bool = false ) {
        var tagBase = tagNumber
        if tagBase == -1 {
            tagBase = value!.DefaultTag
        }
        let field = MetaField( name: name, value: value, tagClass: tagClass, tagNumber: tagBase, optional: optional )
        mutableFields.append( field )
    }

    internal func getField( name: String ) -> ASN1Type? {

        return self.fields.filter { $0.name == name }[ 0 ].value

    }

}


private class CollectionEntry {
    
    internal let tagNumber: Int
    internal let tagClass: TagClass
    internal let value: ASN1Type
    
    init( tagNumber: Int, tagClass: TagClass, value: ASN1Type ) {
        self.tagNumber = tagNumber
        self.tagClass = tagClass
        self.value = value
    }
    
}


public class AbstractCollection: ASN1Type {

    fileprivate var prototype: ASN1Type.Type
    fileprivate var mutableElements: [ ASN1Type ]
    
    public var elements: [ ASN1Type ] { return [ ASN1Type ]( mutableElements ) }

    public init( prototype: ASN1Type.Type ) {
        self.prototype = prototype
        self.mutableElements = []
        super.init()
    }

    public func addElement( element: ASN1Type, tagNumber: Int? = nil, tagClass: TagClass? = nil ) {
        mutableElements.append( element )
        //mutableElements.append( CollectionEntry( tagNumber: mutableElements.count - 1, tagClass: .contextSpecific, value: element )
    }

    // public func removeElement(...)

}


public class SequenceOf: AbstractCollection {

    public override var DefaultTag: Int { return 16 }

    public override init( prototype: ASN1Type.Type ) {
        super.init( prototype: prototype )
    }

}


public class Set: Sequence {

    public override var DefaultTag: Int { return 17 }

    public override init() {
        super.init()
    }

}

//public class UniversalSet : ASN1Type {
//    // Implement collection interface...
//}

public class SetOf: AbstractCollection {

    public override var DefaultTag: Int { return 17 }

    public override init( prototype: ASN1Type.Type ) {
        super.init( prototype: prototype )
    }

}


public class Choice: ASN1Type {

    fileprivate var mutableChoices : [ MetaField ] = []
    
    public var chosen: ASN1Type?

    public init( chosen: ASN1Type? ) {
        super.init()
        self.chosen = chosen
    }

    func registerField( field: MetaField ) {
        if field.tagNumber == -1 {
            field.tagNumber = field.value!.DefaultTag
        }
        mutableChoices.append( field )
    }

}


public class Null: ASN1Type {

    public override var DefaultTag: Int { return 5 }

    public override init() {
        super.init()
    }

}


public class ASN1TypeVisitor {

    fileprivate(set) var level: Int = 0

    public func visit( value: ASN1Type, closure : ( String, Int, String ) -> Void ) throws {

        let name = String( describing: type( of: value ) )

        switch value {

            case is Integer:
                closure( name, level, " ::= \(name)" )

            case is Boolean:
                closure( name, level, " ::= BOOLEAN" )

            case is IA5String:
                closure( name, level, " ::= IA5String" )

            case is PrintableString:
                closure( name, level, " ::= PrintableString" )

            case is UTF8String:
                    closure( name, level, " ::= UTF8String" )

            case is BitString:
                closure( name, level, " ::= BIT STRING" )

            case is OctetString:
                closure( name, level, " ::= OCTET STRING" )

            case let value as ObjectIdentifier:
                closure( name, level, " ::= OBJECT IDENTIFIER( \(value.value) )" )

            case let value as Sequence:
                closure( name, level, "::= SEQUENCE : \(value.fields.count) field(s)" )
                level += 1
                for field in value.fields {
                    if let fieldValue = field.value {
                        try visit( value: fieldValue, closure:closure )
                    } else {
                        if !field.optional {
                            throw ASN1ModelError.requiredFieldAbsentError( name:field.name )
                        }
                    }
                }
                level -= 1

            case let value as Set:
                closure( name, level, "::= SET : \(value.fields.count) field(s)" )
                level += 1
                for field in value.fields {
                    if let fieldValue = field.value {
                        try visit( value: fieldValue, closure:closure )
                    } else {
                        if !field.optional {
                            throw ASN1ModelError.requiredFieldAbsentError( name:field.name )
                        }
                    }
                }
                level -= 1

            case let value as SequenceOf:
                closure( name, level, " ::= SEQUENCE OF : \(value.elements.count) element(s)" )
                level += 1
                for element in value.elements {
                    try visit( value: element, closure:closure )
                }
                level -= 1

            case let value as SetOf:
                closure( name, level, " ::= SET OF : \(value.elements.count) element(s)" )
                level += 1
                for element in value.elements {
                    try visit( value: element, closure:closure )
                }
                level -= 1

            case let value as Choice:
                closure( name, level, " ::= CHOICE" )
                level += 1
                if let chosen = value.chosen {
                    try visit( value: chosen, closure:closure )
                } else {
                    // value.chosen was nil (?): throw DEREncodingError.MisssingValueException
                }
                level -= 1

            case is Null:
                closure( name, level, "::= NULL" )

            case let value as ASN1Any:
                closure( name, level, "::= ANY" )
                level += 1
                if let concreteValue = value.value {
                    try visit( value: concreteValue, closure:closure )
                } else {
                    // concreteValue was nil (?): throw DEREncodingError.MisssingValueException
                }
                level -= 1

            default:
                throw ASN1ModelError.unknownTypeError( value:value )

        }

    }

}


public class ASN1ValuePrinter: ASN1TypeVisitor {

    public func print( value: ASN1Type ) throws {

        Swift.print( "\n\n" )

        try super.visit( value: value ) { name, level, message in

            var indent = ""

            for _ in 0 ..< level {
                indent.append( "  " )
            }

            Swift.print( "\(indent)\(name)\(message)" )

        }

        Swift.print( "\n\n" )

    }

}


extension Data {

    public static func createWithHex( hex: String ) -> Data? {

        let utf8 = hex.utf8
        let length = utf8.count
        let rawData = UnsafeMutablePointer<CUnsignedChar>.allocate( capacity: length / 2 )
        var rawIndex = 0

        for index in stride( from: 0, to:length, by:2 ) {
            let single = NSMutableString()
            single.append( hex.substring( with: (hex.characters.index(hex.startIndex, offsetBy: index) ..< hex.characters.index(hex.startIndex, offsetBy: index + 2)) ) )
            rawData[ rawIndex ] = UInt8( single as String, radix:16 )!
            rawIndex += 1
        }

        let data: Data = Data( bytes: UnsafePointer<UInt8>( rawData ), count: length / 2 )
        rawData.deallocate( capacity: length / 2 )
        return data

    }

}
