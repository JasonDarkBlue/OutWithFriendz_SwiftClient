import UIKit
import ObjectMapper

class Invitation: NSObject, Mappable {
    var id: String?
    var invitationName: String?
    var date: String?
    var possibleInvitationDates: [PossibleInvitationDate]?
    var participants: [Participant]?
    var possiblePlaces: [Restaurant]?
    var host: Participant?
    var eventDate: NSDate?
    var timeStamp: Double?
    var eventPlace: Restaurant?
    var changeIconVisible: BooleanType = false
    
    
    override init(){}
    
    required init?(_ map: Map) {
        super.init()
        mapping(map)
    }
    
    func mapping(map: Map) {
        id <- map["id"]
        invitationName <- map["invitationName"]
        possibleInvitationDates <- map["possibleInvitationDates"]
        participants <- map["users"]
        possiblePlaces <- map["places"]
        host <- map["host"]
        timeStamp <- map["eventDate"]
        /*Date conversion*/
        if (timeStamp != nil){
            timeStamp=timeStamp!/1000
            let convertedDate = NSDate(timeIntervalSince1970:timeStamp!)
            eventDate = convertedDate
        }
        eventPlace <- map["eventPlace"]
    }
}
