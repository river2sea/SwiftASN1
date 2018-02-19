//
//  Resource.swift
//
//  Created by Rowland Smith on 9/26/15.
//  Copyright © 2015 River2Sea. All rights reserved.
//

import Foundation


public enum ModelError: Error {
    case initializationError
}


public class Resource {


    // TODO: Make these properties optional, and don't emit them in toJSON if they are nil.
    //
    public var id: String
    public var etag: String

    
    public init( id: String, etag: String ) {
        self.id = id
        self.etag = etag
    }

    /*
    public required init?( json: JSON ) {
        self.id = ""
        self.etag = ""
        
        if let id: String = "_id" <~~ json {
            self.id = id
        }
        
        if let etag: String = "etag" <~~ json {
            self.etag = etag
        }
        
    }


    public class func createFromJSON( _ json: JSON ) throws -> Glossy {
        return Resource( json: json )!
    }


    public func toJSON() -> JSON? {
        return jsonify( [
            "id" ~~> self.id,
            "etag" ~~> self.etag
        ] )
    }
    
     */

}

