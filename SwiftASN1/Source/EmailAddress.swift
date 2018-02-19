//
//  EmailAddress.swift
//
//  Created by Rowland Smith on 8/13/15.
//  Copyright © 2015 River2Sea. All rights reserved.
//

import Foundation


public class EmailAddress: Decodable, Encodable {

    public var address: String

    
    public convenience init() {
        self.init( address: "" )
    }

    
    public init( address: String ) {
        self.address = address
    }

    /*
    public required init?( json: JSON ) {
        self.address = ( "email" <~~ json )!
    }
    
    
    public func toJSON() -> JSON? {
        return jsonify( [
            "email" ~~> self.address
        ] )
    }
 */
    
    public func isValid() -> Bool {
        abort()
        return true
    }

}
