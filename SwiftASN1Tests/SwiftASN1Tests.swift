//
//  SwiftASN1Tests.swift
//  SwiftASN1Tests
//
//  Created by Rowland Smith on 4/27/17.
//  Copyright © 2017 Rowland Smith. All rights reserved.
//

import XCTest
@testable import SwiftASN1


class SwiftASN1Tests: XCTestCase {

    // swiftlint:disable variable_name
    // swiftlint:disable force_try
    // swiftlint:disable line_length

    /*
     ("Optional( "0341040E5D208C9FE280759C024DA4D5
     BBA0EFA83DA058523487D4DDCB39A423
     03AD1F28A5CF18E7DA691939CBFFEC10
     09D271A70BC5E130797AC3113E190985
     5074A9")" )
     */

    /*
     ("Optional("0341040E5D208C9FE280759C024DA4D5
     BBA0EFA83DA058523487D4DDCB39A423
     03AD1F28A5CF18E7DA691939CBFFEC10
     09D271A70BC5E130797AC3113E190985
     5074A9")")
     */

    let SubjectAltNameOID = SwiftASN1.ObjectIdentifier( string:"2.5.29.17" )

    private let PublicKeyHex = "040E5D208C9FE280759C024DA4D5BBA0" +
        "EFA83DA058523487D4DDCB39A42303AD" +
        "1F28A5CF18E7DA691939CBFFEC1009D2" +
        "71A70BC5E130797AC3113E1909855074" +
        "A9"

    let SignatureHex = "30450221008A0AB506E8BFF9C9730DAD" +
        "1D6C6FF482EB7A47A29A7148A7E1C481" +
        "576D98E5370220158F4C9F2065644586" +
        "3E836AB5547DAA164ACAA031C04F3609" +
        "0BA5A88DF13CA3"


    let rsaAlgorithms = "1.2.840.113549"
    let ecPublicKey = "1.2.840.10045.2.1"
    let ecdsaWithSHA256 = "1.2.840.10045.4.3.2"
    let secp256r1 = "1.2.840.10045.3.1.7"

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    /*
     func testVLQEncoder() {
     let vlq = VLQEncoder()
     let encoding = vlq.encode( value: 113549 )
     print( encoding )
     XCTAssertEqual( [134, 247, 13], encoding )
     }
     */
    func testHexConverter() {
        let data = Data.dataFromHex( PublicKeyHex )
        XCTAssertEqual( PublicKeyHex, data!.hexString() )
        //print( data!.hexString() )
    }

    // swiftlint:disable function_body_length

    func testPrimitiveEncoding() {

        do {
            let data = Data.createWithHex( hex: PublicKeyHex )
            print( data!.hexString() )

            let encoder = DEREncoder( data:Data() )

            encoder.data = Data()
            try encoder.encode( value: Integer( value:0 ) )
            print( encoder.data.hexString() )
            XCTAssertEqual( "020100", encoder.data.hexString(), "Integer(0)" )

            encoder.data = Data()
            try encoder.encode( value: Integer( value:1 ) )
            print( encoder.data.hexString() )
            XCTAssertEqual( "020101", encoder.data.hexString(), "Integer(1)" )

            /* CRASH
             encoder.data = Data()
             try encoder.encodeInteger( value: Integer( value: Int( UINT16_MAX - 1 ) ) )
             print( encoder.data.hexString() )
             try encoder.data.write( to: URL( string: "file:///tmp/integer-max.ber" )! )
             XCTAssertEqual( "020400FFFFFFFE", encoder.data.hexString(), "Integer(UINT32_MAX -1)" )
             */

            encoder.data = Data()
            try encoder.encode( value: Boolean( value:false ) )
            print( encoder.data.hexString() )
            XCTAssertEqual( "010100", encoder.data.hexString(), "Boolean( value:false )" )

            encoder.data = Data()
            try encoder.encode( value: Boolean( value:true ) )
            print( encoder.data.hexString() )
            XCTAssertEqual( "0101FF", encoder.data.hexString(), "Boolean( value:true )" )

            encoder.data = Data()
            try encoder.encode( value: UTF8String( value:"Vince Noir" ) )
            print( "UTF8String: 'Vince Noir': \(encoder.data.hexString())" )
            XCTAssertEqual( "0C0A56696E6365204E6F6972", encoder.data.hexString(), "UTF8String( value:\"Vince Noir\" )" )

            encoder.data = Data()
            //let value = BitString( bytes:[ 0x01, 0x02, 0x03 ] )
            let bitString = BitString( hex: PublicKeyHex )
            print( bitString.value!.hexString() )
            try encoder.encode( value: bitString )
            print( encoder.data.hexString() )
            // TODO: Is this the correct header for this BitString?
            XCTAssertEqual( "034200" + PublicKeyHex, encoder.data.hexString(), "" )

            encoder.data = Data()
            let octetString = OctetString( hex:PublicKeyHex )
            try encoder.encode( value: octetString ) //OctetString( bytes:[ 0x01, 0x02, 0x03, 0x04 ] ) )
            print( encoder.data.hexString() )
            XCTAssertEqual( "0441" + PublicKeyHex, encoder.data.hexString(), "OctetString(value:[ 0x01, 0x02, 0x03, 0x04 ] )" )

            encoder.data = Data()
            try encoder.encode( value: SwiftASN1.ObjectIdentifier( string: ecdsaWithSHA256 ) )
            print( encoder.data.hexString() )
            XCTAssertEqual( "06082A8648CE3D040302", encoder.data.hexString(), ecdsaWithSHA256 )

        } catch let error {
            print("Error info: \(error)")
            XCTFail()
        }

    }

    func testNonce() throws {
        let security = SecurityGuard()
        let nonce = security.generateNonce()
        XCTAssert( !nonce!.isEmpty )
    }

    func testX500Name() {

        // static uint8_t OBJECT_rsaEncryptionNULL[13] = {0x06, 0x09, 0x2A, 0x86, 0x48, 0x86, 0xF7, 0x0D,   0x01, 0x01, 0x01, 0x05, 0x00};

        let atv = AttributeTypeAndValue()
        atv.type = SwiftASN1.ObjectIdentifier( string: rsaAlgorithms )
        atv.value = ASN1Any( value: UTF8String( value: "Vince" ) )
        let rdn = RelativeDistinguishedName()
        rdn.addElement( element: atv )
        let rdnSequence = RDNSequence()
        rdnSequence.addElement( element: rdn )
        let name = Name.createWith( RDNSequence: rdnSequence )
        let output = Data()
        let encoder = DEREncoder( data:output as Data )
        do {
            try encoder.encode( value: name )
            print( output.hexString() )
            try encoder.data.write( to: URL( string: "file:///tmp/name.der" )! )
        } catch {
            print( "Exception:" )
        }

    }

    // swiftlint:enable function_body_length

    func testDEREncoder() {

        do {
            let cr = buildCertificationRequest()
            let output = Data()
            let encoder = DEREncoder( data: output as Data )
            try encoder.encode( value: cr )
            print( encoder.data.hexString() )
            try encoder.data.write( to: URL( string: "file:///tmp/cr.der" )! )
        } catch {
            //...
            print( "Exception:" )
        }

    }

    func decodeOctetString() {
        //let hex = "3011810F56696E636540626F6F73682E636F6D"
        //let decoder = DERDecoder()
        //decoder.decode()
    }

    func testGenerateSignedCSR() {
        let security = SecurityGuard()
        _ = security.generateECDSAKeypair()
        let identity = CSRIdentity( name: "Vince", email: EmailAddress( address: "vince@boosh.com" ), postalCode: "98765", country: "US" )

        //let names = GeneralNames()
        //names.addElement( element: subjectAltName )

        let extensions = Extensions()

        //let basicConstraintsOID = SwiftASN1.ObjectIdentifier( string: "2.5.29.19" )

        // !!! Why is the ASN1Any having it's encodingDirective set to .octetString?
        /*
         let basicConstraints = BasicConstraints() // Already defaults to correct values for this test.
         basicConstraints.pathLenConstraint = nil
         let basicConstraintsExt = Extension( extnID: basicConstraintsOID, critical: Boolean( value: true ), extnValue: ASN1Any( value: basicConstraints ) )
         extensions.addElement( element: basicConstraintsExt )

         let names = GeneralNames()
         let subjectAltName = GeneralName.createWith( rfc822Name: IA5String( value: identity.email.address ) )
         names.addElement( element: subjectAltName )
         let subjectAltNameExt = Extension( extnID: SubjectAltNameOID, critical: Boolean( value: true ), extnValue: ASN1Any( value: names ) )
         extensions.addElement( element: subjectAltNameExt )
         */

        let csrB64 = security.generateCSR( identity: identity, extensions: extensions )
        try! csrB64!.write( toPEM: URL( string: "file:///tmp/Signed-PKC-CSR.b64" )! )
        let csrDER = Data( base64Encoded: csrB64!, options: Data.Base64DecodingOptions.ignoreUnknownCharacters )
        try! csrDER!.write( to: URL( string: "file:///tmp/Signed-CSR.der" )! )
        // TODO: Assert that we have the output that we expect...
        // assertCSRWithPythonCryptography( csrPath: "/tmp/Signed-CSR.der", publicKeyPath:"/tmp/CSRSignersPublicKey.der" )
    }

    func testExtensions() {

        let subjectAltName = GeneralName.createWith( rfc822Name: IA5String( value: "vince@boosh.com" ) )
        let names = GeneralNames()
        names.addElement( element: subjectAltName )
        let extensions = Extensions()

        let subjectAltNameExt = Extension( extnID: SubjectAltNameOID, critical: Boolean( value:true ), extnValue: ASN1Any( value: names ) )
        extensions.addElement( element: subjectAltNameExt )
        let attributes = Attributes()
        attributes.addElement( element: extensions )

        let request = buildCertificationRequest()
        request.certificationRequestInfo.attributes = attributes
        let value = request

        do {

            let encoder = DEREncoder( data: Data() )
            try encoder.encode( value: value )
            try encoder.data.write( to: URL( string: "file:///tmp/Extensions.der" )! )
            try ASN1ValuePrinter().print( value: value )

        } catch let error {
            print( "\n\nError info: \(error)\n" )

            /*for symbol: String in Thread.callStackSymbols {
             print(symbol)
             }*/

            XCTFail()
        }
    }

    fileprivate func assertCSRWithPythonCryptography( csrPath: String, publicKeyPath: String ) {
    }

    func xtestAPICredentials() throws {
        // BROKEN!
        // TODO: We need a keypair in the keychain.
        // Also should we pass the key tag as a parameter to generateAPICredentials?
        //
        let sdc = SecurityGuard()
        let credentials = try sdc.generateAPICredentials( email: "vince@boosh.com" )
        XCTAssertNotNil( credentials )
        print( credentials )

        // TODO: Assert that we have the output that we expect...
        //

    }

    fileprivate func buildCertificationRequest() -> CertificationRequest {

        let name = buildSubjectName()

        //let keyBits = BitString( bytes:[ 0x01, 0x02, 0x03, 0x04 ] ) //hex:PublicKeyHex )
        let keyBits = BitString( hex: PublicKeyHex )
        let id = SwiftASN1.ObjectIdentifier( string: ecPublicKey )
        let parameters = ASN1Any( value: ObjectIdentifier( string: secp256r1 ) )
        let algorithm = AlgorithmIdentifier( algorithm: id, parameters: parameters )
        let spki = SubjectPublicKeyInfo( algorithm: algorithm, subjectPublicKey: keyBits )
        print( "keyBits length: \(keyBits.value!.count)" )
        let cri = CertificationRequestInfo()
        cri.version = Integer( value: 0 )
        cri.subject = name
        cri.subjectPKInfo = spki
        cri.attributes = nil

        let cr = CertificationRequest()
        cr.certificationRequestInfo = cri
        cr.signatureAlgorithm = AlgorithmIdentifier( algorithm: SwiftASN1.ObjectIdentifier( string: ecdsaWithSHA256 ),
                                                     parameters: ASN1Any( value: nil ) )
        cr.signature = BitString( hex: SignatureHex )
        print( "cr.signature length: \(cr.signature.value!.count)" )
        return cr

    }

    fileprivate func buildSubjectName() -> Name {

        let rdnSequence = RDNSequence()

        var rdn = RelativeDistinguishedName()
        rdn = RelativeDistinguishedName()

        /*
         var type = SwiftASN1.ObjectIdentifier( string: "2.5.4.6" )
         var value: ASN1Type = PrintableString( value: "US" )
         rdn.addTypeAndValue( type: type, value: value )
         rdnSequence.addElement( element: rdn )
         */

        rdn = RelativeDistinguishedName()
        let type = SwiftASN1.ObjectIdentifier( string: "2.5.4.3" )
        let value = UTF8String( value: "Vince" )
        rdn.addTypeAndValue( type: type, value: value )
        rdnSequence.addElement( element: rdn )

        /*
         rdn = RelativeDistinguishedName()
         type = SwiftASN1.ObjectIdentifier( string: string:"2.5.4.7" )
         value = UTF8String( value:"Bogus" )
         rdn.addTypeAndValue( type, value:value )
         rdnSequence.addElement( rdn )

         rdn = RelativeDistinguishedName()
         type = SwiftASN1.ObjectIdentifier( string: string:"2.5.4.10" )
         value = UTF8String( value:"Bogus" )
         rdn.addTypeAndValue( type, value:value )
         rdnSequence.addElement( rdn )

         rdn = RelativeDistinguishedName()
         type = SwiftASN1.ObjectIdentifier( string: string:"2.5.4.11" )
         value = UTF8String( value:"Bogus" )
         rdn.addTypeAndValue( type, value:value )
         rdnSequence.addElement( rdn )

         rdn = RelativeDistinguishedName()
         type = SwiftASN1.ObjectIdentifier( string: string:"2.5.4.3" )
         value = UTF8String( value:"Bogus" )
         rdn.addTypeAndValue( type, value:value )
         rdnSequence.addElement( rdn )

         rdn = RelativeDistinguishedName()
         type = SwiftASN1.ObjectIdentifier( string: string:"1.2.840.113549.1.9.1" )
         value = IA5String( value:"bogus@bogus.com" )
         rdn.addTypeAndValue( type, value:value )
         rdnSequence.addElement( rdn )
         */

        return Name.createWith( RDNSequence: rdnSequence )

    }
    
}


extension UInt64 {

    public func binaryString() -> String {

        var value = self
        var binary = ""
        var bitCount = 0

        for _ in 0..<64 {

            if bitCount == 8 {
                binary += " "
                bitCount = 0
            }

            if 0x8000000000000000 & value == 0x8000000000000000 {
                binary += "1"
            } else {
                binary += "0"
            }

            bitCount += 1

            value <<= 1

        }

        return binary

    }

}

