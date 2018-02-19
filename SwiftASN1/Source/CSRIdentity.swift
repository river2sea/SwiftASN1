//
//  CSRIdentity.swift
//
//  Created by Rowland Smith on 5/19/16.
//  Copyright © 2016 River2Sea. All rights reserved.
//

import Foundation


public class CSRIdentity: Resource {


    public var name: String
    public var email: EmailAddress
    public var postalCode: String
    public var country: String
    public var location: String


    public init() {
        self.name = ""
        self.email = EmailAddress()
        self.postalCode = ""
        self.country = ""
        self.location = ""
        super.init( id:"", etag:"" )
    }


    public convenience init( name: String, email: EmailAddress, postalCode: String, country: String ) {
        self.init()
        self.name = name
        self.email = email
        self.postalCode = postalCode
        self.country = country
    }

    // TODO: Implement using Swift4 Codable.

/*
    public required init?( json: JSON ) {
        name = ( "name" <~~ json )!
        email = EmailAddress( address:( "email"  <~~ json )! )
        postalCode = ( "postalCode" <~~ json )!
        country = ( "country" <~~ json )!
        location = ( "location" <~~ json )!
        super.init( json: json )
    }


    public override func toJSON() -> JSON? {
        return jsonify( [
            "id" ~~> self.id,
            "name" ~~> self.name,
            "email" ~~> self.email.address ,
            "postalCode" ~~> self.postalCode ,
            "country" ~~> self.country ,
            "location" ~~> self.location
            ] )
    }

*/
}

