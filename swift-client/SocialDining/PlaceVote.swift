import UIKit
import ObjectMapper

class PlaceVote: NSObject, Mappable {
    
    var id: String?
    var place: Restaurant?
    var invitation: Invitation?
    //To-do: change the below fields to User object and make user object Mappable
    var userName: String?
    var userId: String?
    
    
    override init(){}
    
    required init?(_ map: Map) {
        super.init()
        mapping(map)
    }
    
    func mapping(map: Map) {
        id <- map["id"]
        place <- map["place"]
        invitation <- map["invitation"]
        userId <- map["user.id"]
        userName <- map["user.name"]
    }

   
}
