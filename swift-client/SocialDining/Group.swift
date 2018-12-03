import UIKit

class Group: NSObject {
    var members: [User] = [User]()
    var inviteid: String = String()
    var invitationName: String = String()
    
    func addUser(user:User){
        members.append(user)
    }
}