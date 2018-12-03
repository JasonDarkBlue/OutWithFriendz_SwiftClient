import UIKit
import MapKit
import ObjectMapper

class Restaurant: NSObject, Mappable, MKAnnotation{
    
    var id: NSString?
    var placeId: String?
    var name: String?
    var formattedAddress: String?
    var latitudeDouble: Double?
    var longitudeDouble: Double?
    var desc: String?
    var userId: String?

    var title: String?
    var subtitle: String?
    
    override init(){}
    
    required init?(_ map: Map) {
        super.init()
        mapping(map)
    }
    
    func mapping(map: Map) {
        id <- map["id"]
        placeId <- map["place_id"]
        name <- map["name"]
        formattedAddress <- map["vicinity"]
        latitudeDouble <- map["geometry.location.lat"]
        longitudeDouble <- map["geometry.location.lng"]
        desc = "The same place we meet last time!"
        userId <- map["userId"]
                

        title = name
        subtitle = formattedAddress
    }
    
    var coordinate: CLLocationCoordinate2D{
        var myCoordinate: CLLocationCoordinate2D = CLLocationCoordinate2D()
        myCoordinate.latitude = latitudeDouble!
        myCoordinate.longitude = longitudeDouble!
        return myCoordinate
    }
}
