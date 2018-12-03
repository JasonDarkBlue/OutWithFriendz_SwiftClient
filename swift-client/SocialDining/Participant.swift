//
//  Participant.swift
//  SocialDining
//
//  Created by KHALED ALALNEZI on 6/12/15.
//  Copyright (c) 2015 University of Colorado, Boulder. All rights reserved.
//

import UIKit
import ObjectMapper

class Participant: NSObject, Mappable {
    var id: String?
    var name: String?
    var inviteid: String?
    var userProfileImageUrl: String?
    var facebookId: String?
    
    override init(){}
    
    required init?(_ map: Map) {
        super.init()
        mapping(map)
    }
    
    func mapping(map: Map) {
        id <- map["id"]
        name <- map["name"]
        userProfileImageUrl <- map["userProfileImageUrl"]
        facebookId <- map["facebookId"]
    }
}
