//
//  X509.swift
//  PeaceKeeper
//
//  Created by Rowland Smith on 9/27/16.
//  Copyright © 2016 River2Sea. All rights reserved.
//

import Foundation


// swiftlint:disable force_cast

/*
 BasicConstraints ::= SEQUENCE {
 cA                      BOOLEAN DEFAULT FALSE,
 pathLenConstraint       INTEGER (0..MAX) OPTIONAL }
*/

public class BasicConstraints: Sequence {
    
    public var ca: Boolean {
        get { return self.getField( name: "ca" ) as! Boolean }
        set( newValue ) { mutableFields[ 0 ].value = newValue as Boolean }
    }
    
    // CRASH: We need to be able to set this field to ASN.1 NULL
    //
    public var pathLenConstraint: Integer? {
        
        get {
            if mutableFields[ 1 ].value is Null {
                return nil
            } else {
                return ( self.getField( name: "pathLenConstraint" ) as! Integer )
            }
        }
        
        set( newValue ) {
            if let length = newValue {
                mutableFields[ 1 ].value = length
            } else {
                // Stash in an ANY so we can encapsulate in an OCTET STRING.
                let nullValue = Null()
                nullValue.encodingDirective = .octetString
                mutableFields[ 1 ].value = nullValue
            }
        }
        
    }
    
    override public init() {
        super.init()
        var value: ASN1Type = Boolean( value: false )
        registerField( name: "ca", value: value ) //, tagNumber: value.DefaultTag )
        value = Integer( value: 0 )
        registerField( name: "pathLenConstraint", value: value ) //, tagNumber: value.DefaultTag )
    }
    
}
