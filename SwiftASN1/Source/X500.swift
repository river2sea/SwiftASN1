//
//  X500.swift
//  PeaceKeeper
//
//  Created by Rowland Smith on 11/16/15.
//  Copyright © 2015 River2Sea. All rights reserved.
//

/*

Name ::= CHOICE {
    -- only one possibility for now --
    rdnSequence  RDNSequence
}

RDNSequence ::= SEQUENCE OF RelativeDistinguishedName

RelativeDistinguishedName ::= SET SIZE (1..MAX) OF AttributeTypeAndValue

AttributeTypeAndValue ::= SEQUENCE {
    type     AttributeType,
    value    AttributeValue
}

AttributeType ::= OBJECT IDENTIFIER

AttributeValue ::= ANY -- DEFINED BY AttributeType

*/

// swiftlint:disable force_cast


import Foundation


public class Name: Choice {

    public class func createWith( RDNSequence: RDNSequence ) -> Name {
        let result = Name( chosen: RDNSequence )
        result.registerField( field: MetaField( name: "RDNSequence", value: RDNSequence, tagClass: .universal, tagNumber: -1, optional: false ) )
        return result
    }

    private override init( chosen: ASN1Type? ) {
        super.init( chosen: chosen )
    }

}


public class RDNSequence: SequenceOf /* RelativeDistinguishedName */ {

    public init() {
        super.init( prototype: RelativeDistinguishedName.self )
    }

}


public class RelativeDistinguishedName: SetOf /* AttributeTypeAndValue */ {

    public init() {
        super.init( prototype: AttributeTypeAndValue.self )
    }

    public func addTypeAndValue( type: ObjectIdentifier, value: ASN1Type ) {
        let atv = AttributeTypeAndValue()
        atv.type = type
        atv.value = ASN1Any( value: value )
        addElement( element: atv )
    }

}


public class AttributeTypeAndValue: Sequence {

    public var type: ObjectIdentifier {
        get { return self.getField( name: "type" ) as! ObjectIdentifier }
        set( newValue ) { mutableFields[ 0 ].value = newValue as ObjectIdentifier }
    }

    public var value: ASN1Any {
        get { return self.getField( name: "value" ) as! ASN1Any }
        set( newValue ) { mutableFields[ 1 ].value = newValue as ASN1Any }
    }

    override public init() {
        super.init()
        registerField( name: "type", value: ObjectIdentifier() )
        registerField( name: "value", value: ASN1Any() )
    }

}
