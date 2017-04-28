//
//  ASN1Decoding.swift
//  PeaceKeeper
//
//  Created by Rowland Smith on 12/6/15.
//  Copyright © 2015 River2Sea. All rights reserved.
//

import Foundation



public protocol ASN1Decoder {

    var data: Data { get set }

    func decode( _ value: ASN1Type )

    func decodeTag() -> Int
    func decodeLength() -> Int
    func decodeInteger( _ input: NSMutableData ) -> Integer
    func decodeBoolean() -> Boolean
    func decodeIA5String() -> IA5String
    func decodePrintableString() -> PrintableString
    func decodeUTF8String() -> UTF8String
    func decodeObjectIdentifier() -> ObjectIdentifier
    func decodeBitString( ) -> BitString
    func decodeOctetString() -> OctetString
    func decodeSequence() -> Sequence
    func decodeSequence() -> SequenceOf
    func decodeSet() -> Set
    func decodeSet() -> SetOf
    func decodeChoice() -> ASN1Type
    func decodeASN1Null() -> Null
    func decodeASN1Any() -> ASN1Any

}
