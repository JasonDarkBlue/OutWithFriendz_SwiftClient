import UIKit
import ObjectMapper

class PossibleInvitationDateVote: NSObject, Mappable  {
    
    var id: String?
    var possibleInvitationDate: PossibleInvitationDate?
    var invitation: Invitation?
    //To-do: change below fields to User object and make user object Mappable
    var userName: String?
    var userId: String?
    
    override init(){}
    
    required init?(_ map: Map) {
        super.init()
        mapping(map)
    }
    
    func mapping(map: Map) {
        id <- map["id"]
        possibleInvitationDate <- map["possibleInvitationDate"]
        invitation <- map["invitation"]
        userId <- map["user.id"]
        userName <- map["user.name"]
    }
}
