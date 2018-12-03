import UIKit
import ObjectMapper

class Comment: NSObject, Mappable {
    
    var id: String?
    var content: String?
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
        content <- map["content"]
        invitation <- map["invitation"]
        userId <- map["user.id"]
        userName <- map["user.name"]
    }

   
}
