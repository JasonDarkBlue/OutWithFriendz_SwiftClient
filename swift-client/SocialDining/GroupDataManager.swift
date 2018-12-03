var groupDataManager: GroupDataManager = GroupDataManager()

import UIKit

class GroupDataManager: NSObject{
    
    let TAG = "UserDataManager"
    
    /*A method that returns all current groups in the local database*/
    func getAllGroups()->[Group]{
        var groupArray: [Group] = [Group]()
        if databaseOpenHandler.open(){
            let queryGroupSQL = "SELECT list, names, inviteid, invitationName FROM GROUPLIST"
            let resultsGroup:FMResultSet? = databaseOpenHandler.socialdiningDB!.executeQuery(queryGroupSQL, withArgumentsInArray: nil)
            
            while resultsGroup?.next() == true {
                let group: Group = Group()
                group.inviteid = resultsGroup!.stringForColumn("inviteid")
                group.invitationName = resultsGroup!.stringForColumn("invitationName")
                let list: String = resultsGroup!.stringForColumn("list")
                let listArr = list.characters.split{$0 == "-"}.map(String.init)
                for userFacebookId in listArr{
                    /*Get the user information from local database and add them to the group*/
                    let queryUserSQL = "SELECT id, name, facebookId, userProfileImageUrl FROM USER where facebookId='\(userFacebookId)'"
                    let resultsUser:FMResultSet? = databaseOpenHandler.socialdiningDB!.executeQuery(queryUserSQL, withArgumentsInArray: nil)
                    while resultsUser?.next() == true {
                        let friend: User = User(pName: resultsUser!.stringForColumn("name"), pFacebookId: resultsUser!.stringForColumn("facebookId"))
                        friend.id = resultsUser!.stringForColumn("id")
                        friend.userProfileImageUrl = resultsUser!.stringForColumn("userProfileImageUrl")
                        group.addUser(friend)
                    }
                }
                groupArray.append(group)
            }
            databaseOpenHandler.socialdiningDB!.close()
        } else{
            NSLog("\(self.TAG): Error: \(databaseOpenHandler.socialdiningDB!.lastErrorMessage())")
        }
        return groupArray
    }
    
    /*A method that deletes a group from the local database*/
    func deleteGroupFromLocalDB(inviteid: NSString){
        NSLog("\(self.TAG): Start Delete from LocalDB: Delete Group")
        if databaseOpenHandler.open(){
            let deleteGroupSQL = "DELETE FROM GROUPLIST WHERE inviteid='\(inviteid)'"
            let resultDeleteGroup = databaseOpenHandler.socialdiningDB!.executeUpdate(deleteGroupSQL, withArgumentsInArray: nil)
            if !resultDeleteGroup{
                NSLog("\(self.TAG): DB DEL: Delete Group: Error: \(databaseOpenHandler.socialdiningDB!.lastErrorMessage())")
            } else {
                NSLog("\(self.TAG): DB DEL: Delete Group: Group for invitation: \(inviteid) was successfuly deleted from database")
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    NSNotificationCenter.defaultCenter().postNotificationName("redrawAddFriendViewControllerScreen", object: nil)
                })
            }
        }
    }
}
