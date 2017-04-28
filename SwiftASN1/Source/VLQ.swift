//
//  VLQ.swift
//  PeaceKeeper
//
//  Created by Rowland Smith on 9/25/16.
//  Copyright © 2016 River2Sea. All rights reserved.
//

import Foundation


open class VLQEncoder {
    
    open func encode( value: UInt32 ) -> [ UInt8 ] {
        
        //print( "n: \(n.binaryString())" )
        
        let numRelevantBits = 32 - Int( VLQEncoder.numberOfLeadingZeros( value: UInt32( value ) ) )
        
        var numBytes: Int = Int( ( numRelevantBits + 6 ) / 7 )
        
        if numBytes == 0 {
            numBytes = 1
        }
        
        var output : [ UInt8 ] = Array<UInt8>( repeating: 0, count: Int( numBytes ) )
        var mutableValue = value
        
        for i in ( 0..<numBytes ).reversed() {
            
            //for ( var i = numBytes - 1 ; i >= 0 ; i-- ) {
            
            // Get the first 7 bits of n.
            
            var curByte = ( mutableValue & 0x7F )
            
            if i != ( numBytes - 1 ) {
                // Turn on the high bit if this is the most-significate *byte*.
                curByte |= 0x80
            }
            
            output[ i ] = UInt8( curByte )
            
            mutableValue >>= 7
            
        }
        
        return output
        
    }
    
    // TODO: Support UInt so we can get 32-bits on iOS and 64 bits on OSX.
    //
    open class func numberOfLeadingZeros( value: UInt64 ) -> Int {
        
        if value == 0 {
            return 64
        }
        
        var count: Int = 0
        var mutableValue = value
        
        while mutableValue > 0 {
            if ( 0x8000000000000000 & value ) == 0 {
                count += 1
            } else {
                mutableValue = 0
            }
            mutableValue <<= 1
        }
        
        return count
        
    }
    
    
    // TODO: Support UInt so we can get 32-bits on iOS and 64 bits on OSX.
    //
    open class func numberOfLeadingZeros( value: UInt32 ) -> Int {
        
        if value == 0 {
            return 32
        }
        
        var count: Int = 0
        var mutableValue = value
        
        while mutableValue > 0 {
            if ( 0x80000000 & mutableValue ) == 0 {
                count += 1
            } else {
                mutableValue = 0
            }
            mutableValue <<= 1
        }
        
        return count
        
    }
    
}
