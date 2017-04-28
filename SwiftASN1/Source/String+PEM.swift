//
//  String+PEM.swift
//  PeaceKeeper
//
//  Created by Rowland Smith on 9/26/16.
//  Copyright © 2016 River2Sea. All rights reserved.
//

import Foundation


extension String {
    
    /// Split a string into 32 character lines and wrap in a PEM header/footer.
    
    public func write( toPEM: URL ) throws {
        let header = "-----BEGIN CERTIFICATE REQUEST-----"
        let footer = "-----END CERTIFICATE REQUEST-----"
        let body = self.wrapped( after: 32 )
        let pem = "\(header)\n\(body)\n\(footer)"
        try pem.write( to: toPEM, atomically: false, encoding: String.Encoding.utf8 )
    }

    // From "Advanced Swift", Eidhof et al.
    //
    func wrapped( after: Int ) -> String {
        var i = 0
        let lines = self.characters.split( omittingEmptySubsequences: false ) { character in
            if i >= after {
                i = 0
                return true
            } else {
                i += 1
                return false
            }
        }.map( String.init )
        return lines.joined( separator: "\n" )
    }
    
}
