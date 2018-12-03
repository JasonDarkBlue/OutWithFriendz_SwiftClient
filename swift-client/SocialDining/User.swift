import UIKit

class User: NSObject {
    var id: String?
    var name: String?
    var facebookId: String?
    var emailAddress: String?
    var userProfileImageUrl: String?
    
    
    init(pName: String, pFacebookId: String) {
        name = pName
        facebookId = pFacebookId
    }
}
