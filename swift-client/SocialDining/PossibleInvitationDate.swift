import UIKit
import ObjectMapper

class PossibleInvitationDate: NSObject, Mappable {
    var id: NSString?
    var eventDate: NSDate?
    var timeStamp: Double?
    
    override init(){}
    
    required init?(_ map: Map) {
        super.init()
        mapping(map)
    }
    
    func mapping(map: Map) {
        id <- map["id"]
        /*Date conversion*/
        timeStamp <- map["eventDate"]
        timeStamp=timeStamp!/1000
        let convertedDate = NSDate(timeIntervalSince1970:timeStamp!)
        eventDate = convertedDate
    }
}




