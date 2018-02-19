//
//  PKCS10.swift
//  PeaceKeeper
//
//  Created by Rowland Smith on 11/14/15.
//  Copyright © 2015 River2Sea. All rights reserved.
//

/*
 162  62:     [0] { (SET OF)
 164  60:       SEQUENCE { (Attribute)
 166   9:         OBJECT IDENTIFIER extensionRequest (1 2 840 113549 1 9 14)
 177  47:         SET { (AttributeSetValue => SET OF ANY)
 179  45:           SEQUENCE { (SEQUENCE OF)
 181  12:             SEQUENCE { (EXTENSION)
 183   3:               OBJECT IDENTIFIER basicConstraints (2 5 29 19)
 188   1:               BOOLEAN TRUE
 191   2:               OCTET STRING, encapsulates {
 193   0:                 SEQUENCE {}
 :                        }
 :                      }
 195  29:             SEQUENCE { (EXTENSION)
 197   3:               OBJECT IDENTIFIER subjectAltName (2 5 29 17)
 202   1:               BOOLEAN TRUE
 205  19:               OCTET STRING, encapsulates {
 207  17:                 SEQUENCE {
 209  15:                   [1] 'vince@boosh.com'
 :                        }
     :                 }
     :               }
     :             }
     :           }
     :         }
     :       }
     :     }
*/

/// TODO: Add support for IMPLICIT/EXPLICIT tagging. -rds

// swiftlint:disable force_cast


import Foundation


public struct PKCS10 {
    
    public static let ExtensionRequestOID = ObjectIdentifier( string: "1.2.840.113549.1.9.14" )

}


public class Attributes: SetOf {

    public init() {
        super.init( prototype : AttributeTypeAndValue.self )
    }

}

/*
 Extensions ::= SEQUENCE SIZE (1..MAX) OF Extension
*/

public class Extensions: SequenceOf {

    public init() {
        super.init( prototype: Extension.self )
    }

}


/*
 Extension ::= SEQUENCE  {
    extnID      OBJECT IDENTIFIER,
    critical    BOOLEAN DEFAULT FALSE,
    extnValue   ANY
*/

public class Extension: Sequence {

    public var extnID: ObjectIdentifier {
        get { return self.getField( name: "extnID" ) as! ObjectIdentifier }
        set( newValue ) { mutableFields[ 0 ].value = newValue as ObjectIdentifier }
    }

    public var critical: Boolean {
        get { return self.getField( name: "critical" ) as! Boolean }
        set( newValue ) { mutableFields[ 1 ].value = newValue as Boolean }
    }

    public var extnValue: ASN1Any {
        get { return self.getField( name: "extnValue" ) as! ASN1Any }
        set( newValue ) { mutableFields[ 2 ].value = newValue as ASN1Any }
    }

    public init( extnID: ObjectIdentifier, critical: Boolean = Boolean( value: false ), extnValue: ASN1Any? ) {
        super.init()
        registerField( name: "extnID", value: extnID )
        registerField( name: "critical", value: critical )
        //extnValue!.encodingDirective = .octetString
        registerField( name: "extnValue", value: extnValue )
    }

}


/*
    SubjectAltName ::= GeneralNames

    GeneralNames ::= SEQUENCE SIZE (1..MAX) OF GeneralName

     GeneralName ::= CHOICE {
         otherName                       [0]     OtherName,
         rfc822Name                      [1]     IA5String,
         dNSName                         [2]     IA5String,
         x400Address                     [3]     ORAddress,
         directoryName                   [4]     Name,
         ediPartyName                    [5]     EDIPartyName,
         uniformResourceIdentifier       [6]     IA5String,
         iPAddress                       [7]     OCTET STRING,
         registeredID                    [8]     OBJECT IDENTIFIER
     }
*/


public class GeneralNames: SequenceOf {

    public init() {
        super.init( prototype: GeneralName.self )
    }
    
}


/*
 Much like a Swift enum, ther can be only one. -rds
 There will only be one 'chosen' value and one matching Field of metadata.
*/
public class GeneralName: Choice {

    public class func createWith( rfc822Name: IA5String ) -> GeneralName {
        let result = GeneralName( chosen: rfc822Name )
        result.registerField( field: MetaField( name: "rfc822Name", value: rfc822Name, tagClass: .contextSpecific, tagNumber: 1, isOptional: false ) )
        return result
    }
    
    public class func createWith( dNSName: IA5String ) -> GeneralName {
        let result = GeneralName( chosen: dNSName )
        result.registerField( field: MetaField( name: "dNSName", value: dNSName, tagClass: .contextSpecific, tagNumber: 2, isOptional: false ) )
        return result
    }
    
    fileprivate override init( chosen: ASN1Type? ) {
        super.init( chosen: chosen )
    }

}


public class AlgorithmIdentifier: Sequence {

    public var algorithm: ObjectIdentifier {
        get { return self.getField( name: "algorithm" ) as! ObjectIdentifier }
        set( newValue ) { mutableFields[ 0 ].value = newValue as ObjectIdentifier }
    }

    public var parameters: ASN1Any {
        get { return self.getField( name: "parameters" ) as! ASN1Any }
        set( newValue ) { mutableFields[ 1 ].value =  newValue as ASN1Any }
    }

    public init( algorithm: ObjectIdentifier, parameters: ASN1Any ) {
        super.init()
        registerField( name: "algorithm", value: algorithm )
        registerField( name: "parameters", value: parameters, isOptional: true )
    }

}


public class SubjectPublicKeyInfo: Sequence {

    public var algorithm: AlgorithmIdentifier {
        get { return self.getField( name: "algorithm" ) as! AlgorithmIdentifier }
        set( newValue ) { mutableFields[ 0 ].value = newValue as AlgorithmIdentifier }
    }

    public var subjectPublicKey: BitString {
        get { return self.getField( name: "subjectPublicKey" ) as! BitString }
        set( newValue ) { mutableFields[ 1 ].value = newValue as BitString }
    }

    public convenience override init() {
        self.init(
            algorithm:AlgorithmIdentifier( algorithm: ObjectIdentifier( string: "" ), parameters: ASN1Any() ),
            subjectPublicKey: BitString( bytes: [ UInt8 ]() )
        )
    }

    public init( algorithm: AlgorithmIdentifier, subjectPublicKey: BitString ) {
        super.init()
        registerField( name: "algorithm", value: algorithm )
        registerField( name: "subjectPublicKey", value: subjectPublicKey )
    }

}


public class CertificationRequestInfo: Sequence {

    public var version: Integer {
        get { return self.getField( name: "version" ) as! Integer }
        set( newValue ) { mutableFields[ 0 ].value = newValue as Integer }
    }

    public var subject: Name {
        get { return self.getField( name: "subject" ) as! Name }
        set( newValue ) { mutableFields[ 1 ].value = newValue as Name }
    }

    public var subjectPKInfo: SubjectPublicKeyInfo {
        get { return self.getField( name: "subjectPKInfo" ) as! SubjectPublicKeyInfo }
        set( newValue ) { mutableFields[ 2 ].value = newValue as SubjectPublicKeyInfo }
    }

    public var attributes: Attributes? {
        get { return self.getField( name: "attributes" ) as? Attributes }
        set( newValue ) { mutableFields[ 3 ].value = newValue as Attributes?  }
    }

    public override init() {
        super.init()
        registerField( name: "version", value: Integer( value: 0 ) )
        registerField( name: "subject", value: Name.createWith( RDNSequence: RDNSequence() ) )
        let algorithmId = AlgorithmIdentifier( algorithm: ObjectIdentifier(), parameters: ASN1Any() )
        registerField( name: "subjectPKInfo", value: SubjectPublicKeyInfo( algorithm: algorithmId, subjectPublicKey: BitString( bytes: [ UInt8 ]() ) ) )
        registerField( name: "attributes", value: Attributes(), tagClass: .contextSpecific, tagNumber: 0, isOptional: true )
    }

}


public class CertificationRequest: Sequence {

    public var certificationRequestInfo: CertificationRequestInfo {
        get { return self.getField( name: "certificationRequestInfo" ) as! CertificationRequestInfo }
        set( newValue ) { mutableFields[ 0 ].value = newValue as CertificationRequestInfo }
    }

    public var signatureAlgorithm: AlgorithmIdentifier {
        get { return self.getField( name: "signatureAlgorithm" ) as! AlgorithmIdentifier }
        set( newValue ) { mutableFields[ 1 ].value = newValue as AlgorithmIdentifier }
    }

    public var signature: BitString {
        get { return self.getField( name: "signature" ) as! BitString }
        set( newValue ) { mutableFields[ 2 ].value = newValue as BitString }
    }

    public override init() {
        super.init()
        let certificationRequestInfo    = CertificationRequestInfo()
        let signatureAlgorithm          = AlgorithmIdentifier( algorithm: ObjectIdentifier(), parameters: ASN1Any( value: Null() ) )
        let signature                   = BitString( bytes: [ UInt8 ]() )
        registerField( name: "certificationRequestInfo", value: certificationRequestInfo )
        registerField( name: "signatureAlgorithm", value: signatureAlgorithm )
        registerField( name: "signature", value: signature )
    }

}
