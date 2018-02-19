//
//  SecurityGuard.swift
//  SwiftASN1
//
//  Created by Rowland Smith on 2/18/18.
//  Copyright © 2018 Rowland Smith. All rights reserved.
//

import Foundation
import CommonCrypto

private let ASYMMETRIC_KEY_TAG = "org.river2sea.exampleKey"
private let SUBJECT_PUBLIC_KEY_INFO_PATH = "/tmp/spki.der"

private let ASYMMETRIC_KEY_SIZE = 256
private let NONCE_SIZE = 32

private let AUTHENTICATION_PREFIX = "RIVER2SEA-TOKEN"

private let ecPublicKeyOID = "1.2.840.10045.2.1"
private let ecdsaWithSHA256OID = "1.2.840.10045.4.3.2"
private let secp256r1OID = "1.2.840.10045.3.1.7"

// SECP256R1 EC public key header (length + EC params (sequence) + bitstring
//
private let Secp256r1CurveLen = 256
private let Secp256r1header: [UInt8] = [0x30, 0x59, 0x30, 0x13, 0x06, 0x07, 0x2A, 0x86, 0x48, 0xCE, 0x3D, 0x02, 0x01, 0x06, 0x08, 0x2A, 0x86, 0x48, 0xCE, 0x3D, 0x03, 0x01, 0x07, 0x03, 0x42, 0x00]
private let Secp256r1headerLen = 26

private let Secp384r1CurveLen = 384
private let Secp384r1header: [UInt8] = [0x30, 0x76, 0x30, 0x10, 0x06, 0x07, 0x2A, 0x86, 0x48, 0xCE, 0x3D, 0x02, 0x01, 0x06, 0x05, 0x2B, 0x81, 0x04, 0x00, 0x22, 0x03, 0x62, 0x00]
private let Secp384r1headerLen = 23

private let Secp521r1CurveLen = 521
private let Secp521r1header: [UInt8] = [0x30, 0x81, 0x9B, 0x30, 0x10, 0x06, 0x07, 0x2A, 0x86, 0x48, 0xCE, 0x3D, 0x02, 0x01, 0x06, 0x05, 0x2B, 0x81, 0x04, 0x00, 0x23, 0x03, 0x81, 0x86, 0x00]
private let Secp521r1headerLen = 25


public typealias NameAndOID = ( name: String, oid: SwiftASN1.ObjectIdentifier )

public typealias TypeAndValue = ( type: SwiftASN1.ObjectIdentifier, value: String )


public enum SecurityGuardError: Error {
    case componentError( code: String, oid: SwiftASN1.ObjectIdentifier )
    case nonceGenerationError
}


public class NameBuilder {
    /*
     Required user DN components for PeackeKeaper PKI.

     - CN (commonName)         : name
     - PC (postalCode)         : zipCode
     - C (country)             : country
     - DEVICE (device)         : deviceId
     - E                       : email
     */


    public static let COMMON_NAME    = ObjectIdentifier( string: "2.5.4.3" )
    public static let POSTAL_CODE    = ObjectIdentifier( string: "2.5.4.17" )
    public static let COUNTRY        = ObjectIdentifier( string: "2.5.4.6" )
    public static let DEVICE         = ObjectIdentifier( string: "2.5.6.14" )
    public static let UID            = ObjectIdentifier( string: "0.9.2342.19200300.100.1.1" )

    /// NOTE: We are supporting the deprecated (E)mail attribute for
    /// CSR/Certificate subject/issuer names until we have full support
    /// for the subjectAltName CSR/Certificate extension in the SwiftASN1 module. -rds

    public static let E = ObjectIdentifier( string:"1.2.840.113549.1.9.1" )

    public func buildUserCertificateName( commonName: String, postalCode: String, country: String, device: String, uid: String ) -> RDNSequence? {
        let name = self.buildName(components: [
            ( NameBuilder.COMMON_NAME, commonName ),
            ( NameBuilder.POSTAL_CODE, postalCode ),
            ( NameBuilder.COUNTRY, country ),
            ( NameBuilder.DEVICE, device ),
            ( NameBuilder.UID, uid )
            ])
        return name
    }

    public func buildUserCSRName( commonName: String, postalCode: String, country: String, device: String ) -> RDNSequence? {
        let name = self.buildName(components: [
            ( NameBuilder.COMMON_NAME, commonName ),
            ( NameBuilder.POSTAL_CODE, postalCode ),
            ( NameBuilder.COUNTRY, country ),
            ( NameBuilder.DEVICE, device ),
            ])
        return name
    }

    public func buildUserCSRNameWithIdentity( identity: CSRIdentity ) -> RDNSequence? {
        let name = self.buildName( components: [
            ( NameBuilder.COMMON_NAME, identity.name ),
            ( NameBuilder.POSTAL_CODE, identity.postalCode ),
            ( NameBuilder.COUNTRY, identity.country ),
            ( NameBuilder.E, identity.email.address )
            ] )
        return name
    }

    private func buildName( components : [ TypeAndValue ] ) -> RDNSequence? {
        let rdnSequence = RDNSequence()
        for typeAndValue in components {
            let rdn = RelativeDistinguishedName()
            let type: SwiftASN1.ObjectIdentifier = typeAndValue.type
            let value = UTF8String( value:typeAndValue.value )
            rdn.addTypeAndValue( type: type, value: value )
            rdnSequence.addElement( element: rdn )
        }
        return rdnSequence
    }

}


public class SecurityGuard {

    // {iso(1) member-body(2) us(840) ansi-x962(10045) signatures(4) ecdsa-with-SHA2(3) ecdsa-with-SHA256(2)}
    //
    public var publicKey: SecKey {
        return self.getPublicKeyReference()!
    }

    public var privateKey: SecKey {
        return self.getPrivateKeyReference()!
    }

    private var publicKeyData: Data? {
        return self.getPublicKeyData()
    }

    private var subjectPublicKeyInfo: Data?

    
    public init() {}

    /**
     * Generate an ECDSA keypair and store it in the user's keychain.
     * If a keypair already exists with ASYMMETRIC_KEY_TAG, it is replaced.
     */
    public func generateECDSAKeypair() -> OSStatus {

        let status = self.createSecureKeyPair( keyTag: ASYMMETRIC_KEY_TAG )

        if status == 0 {

            //self.publicKeyData = self.getPublicKeyData( ASYMMETRIC_KEY_TAG )
            var bytes = Array<UInt8>( repeating:0, count:self.publicKeyData!.count )
            self.publicKeyData!.copyBytes( to: &bytes, count:self.publicKeyData!.count )
            print( self.publicKeyData!.hexString() )

            // For examining the SPKI outside of the keychain.
            //
            self.subjectPublicKeyInfo = self.exportECPublicKeyToDER( rawPublicKeyBytes: self.publicKeyData!,
                                                                     keyType:kSecAttrKeyTypeEC as String,
                                                                     keySize: ASYMMETRIC_KEY_SIZE )

            do {
                try self.subjectPublicKeyInfo!.write( to: URL( fileURLWithPath: SUBJECT_PUBLIC_KEY_INFO_PATH ) )
                return 0
            } catch let e {
                NSLog( e.localizedDescription )
                return -1
            }

        } else {
            print( "ECDSA Keypair generation failed." )
            // Report error.
            return status
        }

    }

    /**
     * Generate a CertificateSigningRequest(CSR) containing the
     * user's public-key and signed with the user's private-key.
     * Return a DER encoded CSR wrapped in a Base64 string.
     */
    public func generateCSR( identity: CSRIdentity, extensions: Extensions? = nil ) -> String? {

        let privateKey = getPrivateKeyReference()
        let publicKey = getPublicKeyData()
        let rdnSequence = NameBuilder().buildUserCSRNameWithIdentity( identity: identity )
        let subject = Name.createWith( RDNSequence: rdnSequence! )
        let keyBits = BitString( data: publicKey! )
        let id = ObjectIdentifier( string: ecPublicKeyOID )
        let parameters = ASN1Any( value: ObjectIdentifier( string: secp256r1OID ) )
        let algorithm = AlgorithmIdentifier( algorithm: id, parameters: parameters )
        let spki = SubjectPublicKeyInfo( algorithm: algorithm, subjectPublicKey: keyBits )
        let certRequestInfo = CertificationRequestInfo()
        certRequestInfo.version = Integer( value: 0 )
        certRequestInfo.subject = subject
        certRequestInfo.subjectPKInfo = spki
        certRequestInfo.attributes = nil

        // Add extensions:
        // NOTE: Extension encoding is currently non-functional. -rds
        //
        if let extensions = extensions {
            let attributes = Attributes()
            let attribute = AttributeTypeAndValue()
            attribute.type = PKCS10.ExtensionRequestOID
            attributes.addElement( element: extensions )
            certRequestInfo.attributes = attributes
        }

        // Encode the CertificationRequestInfo and sign it with the user's private key.

        var certRequestInfoDER = Data()
        let encoder = DEREncoder( data: certRequestInfoDER )

        do {
            // Debug Only.
            // ASN1ValuePrinter.print(...) should NOT throw, just print the exception.
            //try ASN1ValuePrinter().print( value: certRequestInfo )
            try encoder.encode( value: certRequestInfo )
            certRequestInfoDER = encoder.data
        } catch {
            print( "\(error)" )
        }

        let signature = self.signData( data: certRequestInfoDER as Data, privateKeyRef: privateKey! )
        let certRequest = CertificationRequest()
        certRequest.certificationRequestInfo = certRequestInfo
        certRequest.signatureAlgorithm = AlgorithmIdentifier( algorithm: ObjectIdentifier( string:ecdsaWithSHA256OID ), parameters:ASN1Any( value: nil ) )
        certRequest.signature = BitString( data: signature! )
        var certRequestDER = Data()

        do {
            // Reset the encoder and encode the CertificationRequest.
            //
            encoder.data = certRequestDER
            try encoder.encode( value: certRequest )
            certRequestDER = encoder.data
        } catch {
            print( "\(error)" )
        }

        // TODO: Encode the CSR in the DER binary format and then wrap in Base64.
        //
        let certRequestBase64 = certRequestDER.base64EncodedString( options: Data.Base64EncodingOptions( rawValue: 0 ) )
        NSLog( "certRequesetBase64: \(certRequestBase64)" )
        return certRequestBase64

    }

    /**
     Generate and sign a random 256-bit nonce.
     Return the nonce and the signature in a colon delimited
     string that is base64 encoded.

     TODO: Sign the combination of email:nonce ?
     */
    public func generateAPICredentials( email: String ) throws -> String {
        if let nonce = generateNonce() {
            let signature = signData( data: nonce, privateKeyRef: getPrivateKeyReference()! )
            let credentials = "\(AUTHENTICATION_PREFIX) \(email):\(nonce.hexString()):\(signature!.hexString())"
            return credentials
        } else {
            throw SecurityGuardError.nonceGenerationError
        }
    }

    /**
     Our server platform, Python, generates RFC 4122 v4 UUIDs with
     lowercase letters for the hex values. I find this easier
     to read than the uppercase that iOS generates, so for now
     we're standardizing on lowercase. -rds
     public func generateUUID() -> String {
     let uuid = UUID()
     return uuid.uuidString.lowercased()
     }
     */

    public func generateNonce() -> Data? {
        var nonce = Data( count: NONCE_SIZE )
        let count = nonce.count
        let _ = nonce.withUnsafeMutableBytes { mutableBytes in
            SecRandomCopyBytes( kSecRandomDefault, count, mutableBytes )
        }
        return nonce
    }

    public func signData( data: Data, privateKeyRef: SecKey ) -> Data? {

        let hashData = NSMutableData( length: Int( CC_SHA256_DIGEST_LENGTH ) )
        //let hash = UnsafePointer( hashData!.mutableBytes )
        var hash = [UInt8]( repeating: 0, count: Int( CC_SHA256_DIGEST_LENGTH ) )
        //CC_SHA256( UnsafeRawPointer( data.bytes ), CC_LONG( data.length ), hash )
        CC_SHA256( hashData?.bytes, CC_LONG( data.count ), &hash )
        //var signature = UnsafeMutablePointer<UInt8>()
        var signature = Array<UInt8>( repeating:0, count:128 )
        var resultLength = signature.count
        let status = SecKeyRawSign( privateKeyRef, [], hash, hashData!.length, &signature, &resultLength)

        if status != 0 {
            // Fail.
            NSLog( "Signature operation failed: \(status)" )
            return nil
        }

        return Data( bytes:signature, count:resultLength )

    }

    /**
     Sign and encrypt a message in accordance with PKCS#7.
     */
    public func signAndEncryptData( message: Data, senderPrivateKey: SecKey, recipientPublicKey: SecCertificate ) -> Data? {

        //let status = CMSEncodeContent( signers, recipients, eContentTypeOID, detachedConten, signedAttributes, content, contentLen, encodedContentOut )

        return nil
    }

    /**
     Store the www.peacekeeper.org root certificate in the user keychain.
     */
    public func registerTrustAnchor( rootCertificate : Any ) {
        // TBD
        abort()
    }

    /**
     Get the Keeper's certificate from the user keychain.
     */
    public func getUserCertificate() -> Data? {
        // TBD
        return nil
    }

    /**
     Store the Keeper's certificate in the user keychain.
     */
    public func setUserCertificate( armoredCertificate: String ) {
        // TBD
        abort()
    }

    // MARK: Private

    /**
     * Validate the www.peacekeeper.org certificate.
     */
    private func validateTrustAnchor( certificate : Any ) {
    }

    private func deleteSecureKeyPair( keyTag: String, completion: ( ( Bool ) -> Void )? ) {

        let query = [
            kSecClass as String : kSecClassKey,
            kSecAttrKeyType as String : kSecAttrKeyTypeEC as String,
            kSecAttrApplicationTag as String : ASYMMETRIC_KEY_TAG
            ,
            ] as [String : Any]

        let status = SecItemDelete( query as CFDictionary )
        print( status )
    }

    private func createSecureKeyPair( keyTag: String ) -> OSStatus {

        // PrivateKey parameters.
        //
        let privateKeyParams: [ String: AnyObject ] = [
            kSecAttrIsPermanent as String: true as AnyObject,
            kSecAttrApplicationTag as String: keyTag as AnyObject,
            ]

        // PublicKey parameters.
        //
        let publicKeyParams: [ String: AnyObject ] = [
            kSecAttrApplicationTag as String: keyTag as AnyObject,
            kSecAttrIsPermanent as String: true as AnyObject
        ]

        // Global parameters for our key generation.
        //
        let parameters: [ String: AnyObject ] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeEC as String as String as AnyObject,
            kSecAttrKeySizeInBits as String: ASYMMETRIC_KEY_SIZE as AnyObject,
            kSecPublicKeyAttrs as String: publicKeyParams as AnyObject,
            kSecPrivateKeyAttrs as String: privateKeyParams as AnyObject,
            ]

        var publicKey, privateKey: SecKey?
        let status = SecKeyGeneratePair( parameters as CFDictionary, &publicKey, &privateKey )
        return status

    }

    private func getPublicKeyReference() -> SecKey? {
        return getKeyReference( keyTag: ASYMMETRIC_KEY_TAG, keyClass:kSecAttrKeyClassPublic as String )
    }

    private func getPrivateKeyReference() -> SecKey? {
        return getKeyReference( keyTag: ASYMMETRIC_KEY_TAG, keyClass:kSecAttrKeyClassPrivate as String )
    }

    private func getKeyReference( keyTag: String, keyClass: String ) -> SecKey? {

        let parameters = [
            kSecClass as String: kSecClassKey,
            kSecAttrKeyType as String: kSecAttrKeyTypeEC,
            kSecAttrKeyClass as String: keyClass,
            kSecAttrApplicationTag as String: keyTag,
            kSecReturnRef as String: true
            ] as [String : Any]

        var data: AnyObject?
        let status = SecItemCopyMatching( parameters as CFDictionary, &data )

        if status == errSecSuccess {
            // swiftlint:disable force_cast
            return ( data as! SecKey )
            // swiftlint:enable force_cast
        } else {
            print( "Error getting \(keyClass) reference: \(status)" )
            return nil
        }

    }

    private func getPublicKeyData() -> Data? {
        return getKeyData( keyTag: ASYMMETRIC_KEY_TAG, keyClass:kSecAttrKeyClassPublic as String )
    }

    private func getKeyData( keyTag: String, keyClass: String ) -> Data? {

        let parameters = [
            kSecClass as String: kSecClassKey,
            kSecAttrKeyType as String: kSecAttrKeyTypeEC,
            kSecAttrKeyClass as String: keyClass,
            kSecAttrApplicationTag as String: keyTag,
            kSecReturnData as String: true
            ] as [String : Any]

        var data: AnyObject?
        let status = SecItemCopyMatching( parameters as CFDictionary, &data )

        if status == errSecSuccess {
            return data as? Data
        } else {
            print( "Error getting \(keyClass) data: \(status)" )
            return nil
        }

    }

    /**
     * Encode the public-key and the algorithm/parameters in a SubjectPublicKeyInfo.
     * This function prepares a EC public key generated with Apple SecKeyGeneratePair to be exported
     * and used outisde iOS, be it openSSL, PHP, Perl, whatever. It basically adds the proper ASN.1
     * header and codifies the result as valid base64 string, 64 characters split.
     * Returns a DER representation of the key.
     */
    private func exportECPublicKeyToDER( rawPublicKeyBytes: Data, keyType: String, keySize: Int) -> Data {

        print( "Exporting EC raw key: \(rawPublicKeyBytes)" )

        // first retrieve the header with the OID for the proper key curve.

        let curveOIDHeader: [UInt8]
        let curveOIDHeaderLen: Int

        switch keySize {

        case Secp256r1CurveLen:
            curveOIDHeader = Secp256r1header
            curveOIDHeaderLen = Secp256r1headerLen

        case Secp384r1CurveLen:
            curveOIDHeader = Secp384r1header
            curveOIDHeaderLen = Secp384r1headerLen

        case Secp521r1CurveLen:
            curveOIDHeader = Secp521r1header
            curveOIDHeaderLen = Secp521r1headerLen

        default:
            curveOIDHeader = []
            curveOIDHeaderLen = 0

        }

        var data = Data( bytes: curveOIDHeader, count: curveOIDHeaderLen )
        data.append( rawPublicKeyBytes as Data )
        return data as Data

    }

}
