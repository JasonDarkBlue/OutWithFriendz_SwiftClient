var userDataManager: UserDataManager = UserDataManager()

import UIKit
import CoreData

class UserDataManager: NSObject {
    
    let TAG = "UserDataManager"
    
    func checkIfUserAvailableOnServer(user: User){
        print("We need to check if user is on server...")
    }
    
    func setAuthenticatedUser(orginatingViewController: UIViewController){
        /*1- calls facebook APIs to get user info*/
        /*2- calls facebook APIs to get user friends list*/
        /*3- posts new user object and get socialdining id*/
        /*4- store user information in NSUserDefaults*/
        /*5- store friend list in local database*/

        _ = NSUserDefaults.standardUserDefaults()
        let newUserFacebookParams:  NSMutableDictionary = NSMutableDictionary() /*dictionary used for posting new user to server*/
        var friendsArray: [NSMutableDictionary] = [NSMutableDictionary]()
        
        /*Step 1*/
        let graphRequest : FBSDKGraphRequest = FBSDKGraphRequest(graphPath: "me", parameters: nil)
        graphRequest.startWithCompletionHandler({ (connection, result, error) -> Void in
            if ((error) != nil){
                //Process error
                NSLog("Error getting user information from Facebook: \(error.localizedDescription)")
            }else{
                if let facebookId: NSString = result.valueForKey("id") as? NSString{
                    if let name: NSString = result.valueForKey("name") as? NSString{
                        let facebookIdString = facebookId as String
                        let authenticatedUser: User = User(pName: name as String, pFacebookId: facebookIdString)
                        
                        newUserFacebookParams.setObject(facebookIdString, forKey: "facebookId")
                        newUserFacebookParams.setObject(name as String, forKey: "name")
 

                        
                        if let emailAddress = result.valueForKey("email") as? NSString{
                            authenticatedUser.emailAddress = emailAddress as String
                        }
                        /*Step 2*/
                        let friendsRequest : FBSDKGraphRequest = FBSDKGraphRequest(graphPath: "me/friends", parameters: nil)
                        friendsRequest.startWithCompletionHandler{(connection:FBSDKGraphRequestConnection!, result:AnyObject!, error:NSError!) -> Void in
                            let resultdict = result as! NSDictionary
                            let data : NSArray = resultdict.objectForKey("data") as! NSArray

                            for friendObject in data{
                                let friendId = friendObject["id"] as! String
                                let friendName = friendObject["name"] as! String
                                    
                                /*create friend dictionary and add to array*/
                                let friendDic: NSMutableDictionary = NSMutableDictionary()
                                friendDic.setObject(friendId, forKey: "facebookId")
                                friendDic.setObject(friendName, forKey: "name")
                                    
                                friendsArray.append(friendDic)
                            }//for

                            newUserFacebookParams.setObject(friendsArray, forKey: "friends")
                            
                            let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
                            let connectedToGCM = appDelegate.connectedToGCM
                            NSLog("connected to gcm: \(connectedToGCM)")
                            if connectedToGCM{
                                if let tokenString = appDelegate.tokenString{
                                    newUserFacebookParams.setObject(tokenString, forKey: "androidGCMRegistrationId")
                                }else{
                                    NSLog("\(self.TAG): HttpPost: New User: Failed to get GCM registeration token...")
                                    popupMessageHandler.displayInfoMessage("Registeration error.", content: "Failed to get registeration ID. Please quit the app and relaunch it to complete the registration properly.", viewController: orginatingViewController)
                                }
                            }
                            
                            /*Step 3*/
                            /*First, we need to check if the user is already on server*/
                            let hostFacebookId = newUserFacebookParams.valueForKey("facebookId") as! String
                            
                            let checkUserURL = Config.SERVER_URL+"/users/facebookIds/\(hostFacebookId)"
                            let checkUserRequest = NSMutableURLRequest(URL: NSURL(string: checkUserURL)!)
                            self.httpGet(checkUserRequest){
                                (data, error) -> Void in
                                if error != nil{
                                    print(error)
                                } else{
                                    let userData = data.dataUsingEncoding(NSUTF8StringEncoding)
                                    let json = JSON(data: userData!)
                                    if let jsonArray = json.array{
                                        if jsonArray.count > 0{
                                            NSLog("User is already available on server, just sotre user information locally...")
                                            let userDic: NSMutableDictionary = NSMutableDictionary()
                                            var userJson = jsonArray[0]
                                            let id = userJson["id"].stringValue
                                            let name = userJson["name"].stringValue
                                            let facebookId = userJson["facebookId"].stringValue
                                            userDic.setObject(id, forKey: "id")
                                            userDic.setObject(name, forKey: "name")
                                            userDic.setObject(facebookId, forKey: "facebookId")
                                            self.addUserProfileToNSUserDefaults(userDic)
                                            
                                            if let loggedOut = NSUserDefaults.standardUserDefaults().valueForKey("Logout") as? Bool{
                                                if loggedOut{
                                                    NSUserDefaults.standardUserDefaults().setBool(false, forKey: "Logout")
                                                }else{
                                                    self.synchronizeFriends(friendsArray, socialdiningId: id)
                                                }
                                            }else{
                                                self.synchronizeFriends(friendsArray, socialdiningId: id)
                                            }
                                        } else{
                                            /*Send user dictionary to helper method to post to server since user is not on server*/
                                            NSLog("User not found on server, work on adding the new user along with friends locally...")
                                            self.postNewUserToServer(newUserFacebookParams)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        })
    }
    
    func postNewUserToServer(newUserFacebookParams: NSMutableDictionary){
        /*This function takes user info in dictionary including friends and post them
        to the server. It returns user socialdining Id generated by the server. Then,
        it stores the new user information in NSUserDefaults and synchronize the user
        friends list*/
        
        let request = NSMutableURLRequest(URL: NSURL(string: Config.SERVER_URL+"/users")!)
        let session = NSURLSession.sharedSession()
        request.HTTPMethod = "POST"
        var err: NSError?
        do {
            request.HTTPBody = try NSJSONSerialization.dataWithJSONObject(newUserFacebookParams, options: [])
        } catch let error as NSError {
            err = error
            print("\(self.TAG): \(err?.localizedDescription)")
            request.HTTPBody = nil
        }
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        NSLog("\(self.TAG): HttpPost: New User")
        let task = session.dataTaskWithRequest(request, completionHandler: {data, response, error -> Void in
            do {
                let json = try NSJSONSerialization.JSONObjectWithData(data!, options: [])
                NSLog("\(self.TAG): HttpPost: New User: Successfuly posted new user to server...")
                // Okay, the parsedJSON is here, use the returned JSON to do the following
                // - Create user object and save it to NSUserDefaults
                // - Save user friends information to local database
                let userDic: NSMutableDictionary = NSMutableDictionary()
                if let id = json["id"] as? NSString {
                    userDic.setObject(id, forKey: "id")
                    if let name = json["name"] as? NSString {
                        userDic.setObject(name, forKey: "name")
                    }
                    if let facebookId = json["facebookId"] as? NSString {
                        userDic.setObject(facebookId, forKey: "facebookId")
                    }
                    self.addUserProfileToNSUserDefaults(userDic)
                        
                    if let friendsArray = json["friends"] as? NSArray {
                        self.synchronizeFriends(friendsArray, socialdiningId: id as String)
                    }
                }
            } catch {
                // failure
                NSLog("\(self.TAG): HttpPost: New User: Error: \((error as NSError).localizedDescription)")
            }
        })
        
        task.resume()
    }
    
    /*retrieves user information from NSUserDefaults if they exist, otherwise, return nil*/
    func getAuthenticatedUser()->NSObject?{
        let userDefaults = NSUserDefaults.standardUserDefaults()
        return userDefaults.dictionaryForKey("userDic")
    }
    
    func addUserProfileToNSUserDefaults(userDic: NSMutableDictionary){
        let userDefaults = NSUserDefaults.standardUserDefaults()
        userDefaults.setObject(userDic, forKey: "userDic")
        userDefaults.synchronize()
    }
    
    func synchronizeFriends(friendsArray: NSArray, socialdiningId: String){
        
        /*Users should only be added if they are available on the server and have socialdiningId*/
        if reachabilityStatus == kREACHABLEWITHWIFI || reachabilityStatus == kREACHABLEWITHWWAN{
            /*Get user friends from server*/
            let friendsURL = Config.SERVER_URL+"/users/\(socialdiningId)/socialDiningFriends"
            let request = NSMutableURLRequest(URL: NSURL(string: friendsURL)!)
            httpGet(request){
                (data, error) -> Void in
                if error != nil{
                    print(error)
                } else{
                    let serverFriends = self.convertJsonToArrayOfFriends(data as String)
                    /*add users to local database in case they are available on SocialDining server*/
                    if databaseOpenHandler.open() {
                        for friendDic in friendsArray{
                            let facebookId = friendDic["facebookId"] as! String
                            let foundFriend = serverFriends.filter{ $0.facebookId == facebookId }.first
                            if (foundFriend != nil){
                                let name = friendDic["name"] as! String
                                let userProfileImageUrl = "https://graph.facebook.com/\(facebookId)/picture"
                                NSLog("\(self.TAG): DB INSERT: USER")
                                let insertSQL = "INSERT INTO USER (id, name, facebookId, userProfileImageUrl) VALUES ('\(foundFriend!.id!)', '\(name)', '\(facebookId)', '\(userProfileImageUrl)')"
                                let result = databaseOpenHandler.socialdiningDB!.executeUpdate(insertSQL, withArgumentsInArray: nil)
                                if !result {
                                    NSLog("\(self.TAG): DB INSERT: USER: Error: \(databaseOpenHandler.socialdiningDB!.lastErrorMessage())")
                                } else {
                                    NSLog("\(self.TAG): DB INSERT: USER: Friend: \(name) was successfuly added to database")
                                }
                            }
                        }//for
                    }else{
                        NSLog("\(self.TAG): DB INSERT: USER: Error: \(databaseOpenHandler.socialdiningDB!.lastErrorMessage())")
                    }
                    /*Store the first update time in NSUserDefaults*/
                    let userDefaults = NSUserDefaults.standardUserDefaults()
                    userDefaults.setObject(NSDate(), forKey: "lastUpdateTime")
                }
            }//httpGet
        }else{
            NSLog("\(self.TAG): Unable to synchronize friends, no Internet connection available.")
        }
    }
    
    /*Generic methods to handle http get calls*/
    func httpGet(request: NSURLRequest!, callback: (String, String?) -> Void){
        let session = NSURLSession.sharedSession()
        let task = session.dataTaskWithRequest(request){
            (data, response, error) -> Void in
            if error != nil {
                callback("", error!.localizedDescription)
            } else{
                let result = NSString(data: data!, encoding: NSASCIIStringEncoding)!
                callback(result as String,nil)
            }
        }
        task.resume()
    }
    
    func convertJsonToArrayOfFriends(serverFriendsDataString: NSString) -> [User]{
        var serverFriends = [User]()
        let serverFriendsData = serverFriendsDataString.dataUsingEncoding(NSUTF8StringEncoding)
        let json = JSON(data: serverFriendsData!)
        if let jsonArray = json.array{
            for friendJson in jsonArray{
                if let serverFriendId = friendJson["id"].string{
                    
                    if let serverFriendName = friendJson["name"].string{
                        if let serverFriendFacebookId = friendJson["facebookId"].string{
                            let serverFriend: User = User(pName: serverFriendName, pFacebookId: serverFriendFacebookId)
                            serverFriend.id = serverFriendId
                            serverFriends.append(serverFriend)
                        }
                    }
                }
            }
        }
        NSLog("\(self.TAG): SocialDinign server returned: \(serverFriends.count) friends!")
        return serverFriends
    }
    
    func debugRequest(request: NSMutableURLRequest){
        print("Debug information for URL request: ")
        print(request.allHTTPHeaderFields)
        let body = NSString(data: request.HTTPBody!, encoding: NSUTF8StringEncoding)!
        print(body)
    }
    
    func updateUserFriendsOnServer(userId: String){
        NSLog("\(self.TAG): Start: update user friend list")
        
        var friendsArray: [NSMutableDictionary] = [NSMutableDictionary]()
        let graphRequest : FBSDKGraphRequest = FBSDKGraphRequest(graphPath: "me", parameters: nil)
        graphRequest.startWithCompletionHandler({ (connection, result, error) -> Void in
            if ((error) != nil){
                //Process error
                NSLog("Error getting user information from Facebook: \(error.localizedDescription)")
            }else{
                if let facebookId: NSString = result.valueForKey("id") as? NSString{
                    let friendsRequest : FBSDKGraphRequest = FBSDKGraphRequest(graphPath: "me/friends", parameters: nil)
                    friendsRequest.startWithCompletionHandler{(connection:FBSDKGraphRequestConnection!, result:AnyObject!, error:NSError!) -> Void in
                        let resultdict = result as! NSDictionary
                        let data : NSArray = resultdict.objectForKey("data") as! NSArray
            
                        for friendObject in data{
                            let friendId = friendObject["id"] as! String
                            let friendName = friendObject["name"] as! String
                
                            /*create friend dictionary and add to array*/
                            let friendDic: NSMutableDictionary = NSMutableDictionary()
                            friendDic.setObject(friendId, forKey: "facebookId")
                            friendDic.setObject(friendName, forKey: "name")
                
                            friendsArray.append(friendDic)
                        }//for
                        let updateFriendsURL = Config.SERVER_URL + "/users" + "/\(userId)" + "/friends"
                        let updateFriendsRequest = NSMutableURLRequest(URL: NSURL(string: updateFriendsURL)!)
                        var err: NSError?
                        let session = NSURLSession.sharedSession()
                        updateFriendsRequest.HTTPMethod = "PUT"
                        do{
                            updateFriendsRequest.HTTPBody = try NSJSONSerialization.dataWithJSONObject(friendsArray, options: [])
                        }catch let error as NSError{
                            err = error
                            NSLog("\(self.TAG): HttpPUT: Error: \(err?.localizedDescription)")
                            updateFriendsRequest.HTTPBody = nil
                        }
                        updateFriendsRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
                        updateFriendsRequest.addValue("application/json", forHTTPHeaderField: "Accept")
                        NSLog("\(self.TAG): HttpPut: update friends list")
                        
                        let updateFriendsTask = session.dataTaskWithRequest(updateFriendsRequest, completionHandler: {data,
                            response, error -> Void in
                            do {
                                let _ = try NSJSONSerialization.JSONObjectWithData(data!, options: [])
                                NSLog("\(self.TAG): HttpPUT: Successfully update Place Title to server...")
                            }catch{
                                NSLog("\(self.TAG): HttpPut: \((error as NSError).localizedDescription)")
                            }
                            
                        })
                        updateFriendsTask.resume()
            
                    }
                }
            }
        })
        
               
    }
    
    func getAllFriends()->[User]{
        
        var fBFriendArray: [User] = [User]()
        
        if databaseOpenHandler.open(){
            let querySQL = "SELECT id, name, facebookId, userProfileImageUrl FROM USER"
            let results:FMResultSet? = databaseOpenHandler.socialdiningDB!.executeQuery(querySQL, withArgumentsInArray: nil)
            
            while results?.next() == true {
                let friend: User = User(pName: results!.stringForColumn("name"), pFacebookId: results!.stringForColumn("facebookId"))
                friend.id = results!.stringForColumn("id")
                friend.userProfileImageUrl = results!.stringForColumn("userProfileImageUrl")
                fBFriendArray.append(friend)
            }
            databaseOpenHandler.socialdiningDB!.close()
        } else{
            NSLog("\(self.TAG): Error: \(databaseOpenHandler.socialdiningDB!.lastErrorMessage())")
        }
        
        return fBFriendArray
    }
    
    /*A method to manually synchronize facebook friendships between client and server*/
    func synchronizeFriendsPeriodically(immediate: Bool){
        let userDefaults = NSUserDefaults.standardUserDefaults()
        /*Friendship manual update will happen if one minute elapsed from last launch*/
        let updateInterval = -60.00
        if reachabilityStatus == kREACHABLEWITHWIFI || reachabilityStatus == kREACHABLEWITHWWAN{
            if let userDic = getAuthenticatedUser(){
                let hostId = userDic.valueForKey("id") as? String
                if let lastUpdateTime = NSUserDefaults.standardUserDefaults().objectForKey("lastUpdateTime") as? NSDate{
                    let timeInterval = lastUpdateTime.timeIntervalSinceNow
                    if immediate || timeInterval < updateInterval {
                        NSLog("\(self.TAG): Time elapsed since last update is : \(timeInterval) seconds...")
                        NSLog("\(self.TAG): Synchronizing user friends list with server...")
                        /*Get user friends from server*/
                        let friendsURL = Config.SERVER_URL+"/users/\(hostId!)/socialDiningFriends"
                        let request = NSMutableURLRequest(URL: NSURL(string: friendsURL)!)
                        httpGet(request){
                            (data, error) -> Void in
                            if error != nil{
                                print(error)
                            } else{
                                let serverFriends = self.convertJsonToArrayOfFriends(data as String)
                                NSLog("\(self.TAG): Number of friends from server: \(serverFriends.count)")
                                let localFriends = self.getAllFriends()
                                NSLog("\(self.TAG): Number of local friends: \(localFriends.count)")
                                /*Adding new PossibleInvtationDates*/
                                for serverFriend in serverFriends{
                                    var foundFlag = false
                                    for localFriend in localFriends{
                                        if localFriend.id! == serverFriend.id!{
                                            foundFlag = true
                                        }
                                    }
                                    if !foundFlag{
                                        if databaseOpenHandler.open(){
                                            let userProfileImageUrlString = "https://graph.facebook.com/\(serverFriend.facebookId!)/picture"
                                            NSLog("\(self.TAG): DB INSERT: USER")
                                            let insertFriendSQL = "INSERT INTO USER (id, name, facebookId, userProfileImageUrl) VALUES ('\(serverFriend.id!)', '\(serverFriend.name!)', '\(serverFriend.facebookId!)', '\(userProfileImageUrlString)')"
                                            let resultFriend = databaseOpenHandler.socialdiningDB!.executeUpdate(insertFriendSQL, withArgumentsInArray: nil)
                                            if !resultFriend{
                                                NSLog("\(self.TAG): DB INSERT: USER: Error: \(databaseOpenHandler.socialdiningDB!.lastErrorMessage())")
                                            } else {
                                                NSLog("\(self.TAG): DB INSERT: USER: New friend: \(serverFriend.name!) was successfuly added to local database.")
                                                /*Fire notification about posted Final place*/
                                                notificationHandler.fireNotification("\(serverFriend.name!) has joined OutWithFriendz! You can add them now to your invitations!", alertAction: "open")
                                            }
                                            databaseOpenHandler.socialdiningDB!.close()
                                        }else{
                                            NSLog("\(self.TAG): DB INSERT: USER: Error: \(databaseOpenHandler.socialdiningDB!.lastErrorMessage())")
                                        }
                                    }
                                }
                            }
                        }
                        if !immediate{
                            userDefaults.setObject(NSDate(), forKey: "lastUpdateTime")
                        }
                    }
                }
            }else{
                NSLog("\(self.TAG): HttpGet: Synch friendships: no authenticated user yet...")
            }
        }else{
            NSLog("\(self.TAG): Unable to synchronize friends periodically, no Internet connection available.")
        }
    }
}
