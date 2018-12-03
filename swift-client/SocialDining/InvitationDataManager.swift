var invitationDataManager: InvitationDataManager = InvitationDataManager()


import UIKit
import CoreData
import ObjectMapper

class InvitationDataManager: NSObject {
    
    let TAG = "InvitationDataManager"
   
    var invitations = [Invitation]()
    var addedParticipants: NSSet!
    
    /*A method that receives new invitation object and post it to the server*/
    func postInvitationToServer(invitation: Invitation){

        /*Prepare invitation dictionary object for posting*/
        /*These will be nested with the a root Invitation dictionary object*/
        var possibleInvitationDatesArray: [NSMutableDictionary] = [NSMutableDictionary]()
        var possiblePlacesArray: [NSMutableDictionary] = [NSMutableDictionary]()
        var participantsArray: [NSMutableDictionary] = [NSMutableDictionary]()
        
        /*Root dictionary object for posting new invitation to server*/
        let newInvitatoinParameters:  NSMutableDictionary = NSMutableDictionary()
        newInvitatoinParameters.setObject(invitation.invitationName!, forKey: "invitationName")
        let hostDic: NSMutableDictionary = NSMutableDictionary()
        hostDic.setObject(invitation.host!.id!, forKey: "id")
        hostDic.setObject(invitation.host!.name!, forKey: "name")
        hostDic.setObject(invitation.host!.userProfileImageUrl!, forKey: "userProfileImageUrl")
        newInvitatoinParameters.setObject(hostDic, forKey: "host")
        newInvitatoinParameters.setObject(4, forKey: "clientVersion")
        /*adding nested dates to invitation dictionary*/
        if let possibleInvitationDates = invitation.possibleInvitationDates{
            for possibleInvitationDate in possibleInvitationDates{
                let dateFormatter = NSDateFormatter()
                dateFormatter.dateFormat = "EEE MMM dd HH:mm:ss z yyyy"
                let dateString = dateFormatter.stringFromDate(possibleInvitationDate.eventDate!)
                let newPossibleInvitationDateDic: NSMutableDictionary = NSMutableDictionary()
                newPossibleInvitationDateDic.setObject(dateString, forKey: "eventDate")
                possibleInvitationDatesArray.append(newPossibleInvitationDateDic)
            }
            newInvitatoinParameters.setObject(possibleInvitationDatesArray, forKey: "possibleInvitationDates")
        }
        /*adding nested places to invitation dictionary*/
        if let possiblePlaces = invitation.possiblePlaces{
            for possiblePlace in possiblePlaces{
                let newPossiblePlaceDic: NSMutableDictionary = NSMutableDictionary()
                newPossiblePlaceDic.setObject(possiblePlace.name!, forKey: "name")
                newPossiblePlaceDic.setObject(possiblePlace.placeId!, forKey: "place_id")

                newPossiblePlaceDic.setObject(possiblePlace.formattedAddress!, forKey: "vicinity")
                newPossiblePlaceDic.setObject(possiblePlace.desc!, forKey: "description")
                newPossiblePlaceDic.setObject(possiblePlace.userId!, forKey: "userId")

                possiblePlacesArray.append(newPossiblePlaceDic)
            }
            newInvitatoinParameters.setObject(possiblePlacesArray, forKey: "places")
        }
        /*adding nested participants to invitation dictionary*/
        if let participants = invitation.participants{
            for participant in participants{
                let newParticipantDic: NSMutableDictionary = NSMutableDictionary()
                newParticipantDic.setObject(participant.name!, forKey: "name")
                newParticipantDic.setObject(participant.userProfileImageUrl!, forKey: "userProfileImageUrl")
                newParticipantDic.setObject(participant.id!, forKey: "id")
                newParticipantDic.setObject(participant.facebookId!, forKey: "facebookId")
                participantsArray.append(newParticipantDic)
            }
            newInvitatoinParameters.setObject(participantsArray, forKey: "users")
        }
        /*Prepare HTTP POST request for sending the new Invitation to the server*/
        let request = NSMutableURLRequest(URL: NSURL(string: Config.SERVER_URL+"/invitations")!)
        let session = NSURLSession.sharedSession()
        request.HTTPMethod = "POST"
        let _: NSError?
        request.HTTPBody = try! NSJSONSerialization.dataWithJSONObject(newInvitatoinParameters, options: [])
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        /*Invoke the HTTP POST request*/
        let task = session.dataTaskWithRequest(request, completionHandler: {data, response, error -> Void in
            /*strData containts the body of the response*/
            _ = NSString(data: data!, encoding: NSUTF8StringEncoding)
            let _: NSError?
            let json = try! NSJSONSerialization.JSONObjectWithData(data!, options: .MutableLeaves) as? NSDictionary
            
            // Did the JSONObjectWithData constructor return an error? If so, log the error to the console
            if(error != nil) {
                print(error!.localizedDescription)
                let jsonStr = NSString(data: data!, encoding: NSUTF8StringEncoding)
                NSLog("\(self.TAG): HttpPost: New Invitation: Error could not parse JSON: '\(jsonStr)'")
            }
            else {
                // The JSONObjectWithData constructor didn't return an error. But, we should still
                // check and make sure that json has a value using optional binding.
                if let _ = json {
                    // Okay, the parsedJSON is here, use the returned JSON to do the following
                   NSLog("\(self.TAG): HttpPost: New Invitation: Successfuly posted invitation to server...")
                }
                else {
                    //Json object was nil check if server is running
                    let jsonStr = NSString(data: data!, encoding: NSUTF8StringEncoding)
                    NSLog("\(self.TAG): HttpPost: New Invitation: JSON is null: \(jsonStr)")
                }
            }
        })
        NSLog("\(self.TAG): HttpPost: New Invitation")
        task.resume()
    }
    
    /*A method that receives existing invitation id and delete it from the server*/
    func deleteInvitationFromServer(inviteid: NSString){
        NSLog("\(self.TAG): Start: Delete Invitation")
        let deleteInvitationURL = Config.SERVER_URL+"/invitations/\(inviteid)"
        let request = NSMutableURLRequest(URL: NSURL(string: deleteInvitationURL)!)
        request.HTTPMethod = "DELETE"
        NSLog("\(self.TAG): HttpPost: Delete Invitation")
        httpGet(request){
            (data, error) -> Void in
            if error != nil{
                print(error)
                NSLog("\(self.TAG): HttpPost: Error")
            } else{
                NSLog("Successfully posted delete Invitation to server...")
            }
        }
    }
    
    /*Method to delete an Invitation from local DB when a GCM is receiced*/
    func deleteInvitationFromLocalDB(inviteid: NSString){
        NSLog("\(self.TAG): Start Delete from LocalDB: Delete Invitation")
        ChangeIconVisible().checkChangeIconVisible(inviteid as String)
        if databaseOpenHandler.open(){
            let deleteInvitationSQL = "DELETE FROM INVITATION WHERE id='\(inviteid)'"
            let resultDeleteInvitation = databaseOpenHandler.socialdiningDB!.executeUpdate(deleteInvitationSQL, withArgumentsInArray: nil)
            if !resultDeleteInvitation{
                NSLog("\(self.TAG): DB DEL: Delete Invitation: Error: \(databaseOpenHandler.socialdiningDB!.lastErrorMessage())")
            } else {
                NSLog("\(self.TAG): DB DEL: Delete Invitation: Invitation: \(inviteid) was successfuly deleted from database")
            }
            
            /*Delete possible invitation dates for the invitation*/
            NSLog("\(self.TAG): DB DEL: Delete all possible date votes for invitation")
            let deleteAllPossibleInvitationDatesSQL = "DELETE FROM POSSIBLE_INVITATION_DATE WHERE inviteid='\(inviteid)'"
            let resultDeleteAllPossibleInvitationDates = databaseOpenHandler.socialdiningDB!.executeUpdate(deleteAllPossibleInvitationDatesSQL, withArgumentsInArray: nil)
            if !resultDeleteAllPossibleInvitationDates{
                NSLog("\(self.TAG): DB DEL ALL: Delete all possible date votes for invitation: Error: \(databaseOpenHandler.socialdiningDB!.lastErrorMessage())")
            }else{
                NSLog("\(self.TAG): DB DEL ALL: Successfully deleted all possible invitation dates for the invitation")
            }
            
            /*Delete places for the invitation*/
            NSLog("\(self.TAG): DB DEL: Delete all places for invitation")
            let deleteAllPlacesSQL = "DELETE FROM PLACE WHERE inviteid='\(inviteid)'"
            let resultDeleteAllPlaces = databaseOpenHandler.socialdiningDB!.executeUpdate(deleteAllPlacesSQL, withArgumentsInArray: nil)
            if !resultDeleteAllPlaces{
                NSLog("\(self.TAG): DB DEL ALL: Delete all places for invitation: Error: \(databaseOpenHandler.socialdiningDB!.lastErrorMessage())")
            }else{
                NSLog("\(self.TAG): DB DEL ALL: Successfully deleted all places for the invitation")
            }
            
            /*Delete participants for the ivitation*/
            NSLog("\(self.TAG): DB DEL: Delete all participants for invitation")
            let deleteAllParticipantsSQL = "DELETE FROM PARTICIPANT WHERE inviteid='\(inviteid)'"
            let resultDeleteAllParticipants = databaseOpenHandler.socialdiningDB!.executeUpdate(deleteAllParticipantsSQL, withArgumentsInArray: nil)
            if !resultDeleteAllParticipants{
                NSLog("\(self.TAG): DB DEL ALL: Delete all participants for invitation: Error: \(databaseOpenHandler.socialdiningDB!.lastErrorMessage())")
            }else{
                NSLog("\(self.TAG): DB DEL ALL: Successfully deleted all participants for the invitation")
            }
            
        }
        /*Refresh invitation listing in UI*/
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            NSNotificationCenter.defaultCenter().postNotificationName("redrawInvitationListID", object: nil)
        })
    }
    
    /*A method that receives existing invitation id and returns an invitation object*/
    func getInvitation(inviteid: String) -> Invitation{
        let invitation: Invitation = Invitation()

        if databaseOpenHandler.open(){
            /*Getting Invitation information from local database*/
            let queryInvitationSQL = "SELECT id, invitationName, hostId, eventDate, eventPlace FROM INVITATION WHERE id='\(inviteid)'"
            let invitationResults:FMResultSet? = databaseOpenHandler.socialdiningDB!.executeQuery(queryInvitationSQL, withArgumentsInArray: nil)
            while invitationResults?.next() == true {
                invitation.id = invitationResults!.stringForColumn("id")
                invitation.invitationName = invitationResults!.stringForColumn("invitationName")
                let host: Participant = Participant()
                host.id = invitationResults!.stringForColumn("hostId")
                invitation.host = host
                /*Parsing event date in case it is already set*/
                let eventDateLong = invitationResults!.intForColumn("eventDate")
                if eventDateLong != 0{
                    let seconds = NSTimeInterval(eventDateLong)
                    let eventDate = NSDate(timeIntervalSince1970: seconds)
                    invitation.eventDate = eventDate
                }
                /*Parsing event place in case it is already set*/
                if let eventPlaceString = invitationResults!.stringForColumn("eventPlace"){
                    let eventPlace: Restaurant = Restaurant()
                    eventPlace.id = eventPlaceString
                    eventPlace.name = ""
                    let queryPlaceNameSQL = "SELECT name FROM PLACE WHERE id='\(eventPlaceString)'"
                    let placeNameResults:FMResultSet? = databaseOpenHandler.socialdiningDB!.executeQuery(queryPlaceNameSQL, withArgumentsInArray: nil)
                    while placeNameResults?.next() == true {
                        eventPlace.name = placeNameResults!.stringForColumn("name")
                    }
                    invitation.eventPlace = eventPlace
                }
            }
            invitation.possibleInvitationDates = possibleInvitationDateDataManager.getListOfPossibleInvitationDatesForInvitationFromLocalDB(inviteid)
            invitation.possiblePlaces = restaurantDataManager.getListOfPlacesForInvitationFromLocalDB(inviteid)
            invitation.participants = participantDataManager.getListOfParticipantsForInvitationFromlocalDB(inviteid)
        }
        return invitation
    }

    func getAllInvitationsCount(){
        /*a function that returns number of local invitations*/
    }
    
    func getAllInvitations()->[Invitation]{
        /*a function that returns invitations from local db*/
        var localInvitations: [Invitation] = [Invitation]()
        if databaseOpenHandler.open(){
            let querySQL = "SELECT id, invitationName, hostId, eventDate, eventPlace, changeIconVisible FROM INVITATION where archived=\(0)"
            let results:FMResultSet? = databaseOpenHandler.socialdiningDB!.executeQuery(querySQL, withArgumentsInArray: nil)
            while results?.next() == true {
                let localInvitation: Invitation = Invitation()
                let change = results!.intForColumn("changeIconVisible")
                if change == 1{
                    localInvitation.changeIconVisible = true
                }else{
                    localInvitation.changeIconVisible = false
                }
                localInvitation.id = results!.stringForColumn("id")
                localInvitation.invitationName = results!.stringForColumn("invitationName")
                let host: Participant = Participant()
                host.id = results!.stringForColumn("hostId")
                localInvitation.host = host
                /*Parsing event date in case it is already set*/
                let eventDateLong = results!.intForColumn("eventDate")
                if eventDateLong != 0{
                    let seconds = NSTimeInterval(eventDateLong)
                    let eventDate = NSDate(timeIntervalSince1970: seconds)
                    localInvitation.eventDate = eventDate
                }
                /*Parsing event place in case it is already set*/
                if let eventPlaceId = results!.stringForColumn("eventPlace"){
                    let eventPlace: Restaurant = Restaurant()
                    eventPlace.id = eventPlaceId
                    /*Getting place name from local db*/
                    let queryPlacesSQL = "SELECT name, inviteid, place_id FROM PLACE WHERE id='\(eventPlaceId)'"
                    let results:FMResultSet? = databaseOpenHandler.socialdiningDB!.executeQuery(queryPlacesSQL, withArgumentsInArray: nil)
                     while results?.next() == true {
                        eventPlace.name = results!.stringForColumn("name")
                        eventPlace.placeId = results!.stringForColumn("place_id")
                    }
                    localInvitation.eventPlace = eventPlace
                }
                localInvitations.append(localInvitation)    
            }
        }
        return localInvitations
    }
    
    func synchronizeInvitationsWithServer(){
        NSLog("\(TAG): synchronizeInvitationsWithServer")
        if reachabilityStatus == kREACHABLEWITHWIFI || reachabilityStatus == kREACHABLEWITHWWAN{
        /*Get user ID from NSUserDefaults*/
            if let userDic = userDataManager.getAuthenticatedUser() as? NSDictionary{
                let id = userDic.valueForKey("id") as! String
                let invitationsURL = Config.SERVER_URL+"/invitations/withUser/\(id)"
                let request = NSMutableURLRequest(URL: NSURL(string: invitationsURL)!)
                NSLog("\(TAG): HttpGet: new invitation")
                httpGet(request){
                    (data, error) -> Void in
                    if error != nil{
                        print(error)
                    } else{
                        let serverInvitations = self.convertJsonToArrayOfInvitations(data)
                        /*get all invitations from local database to match and synchronzie*/
                        var localInvitations: [Invitation] = [Invitation]()
                        if databaseOpenHandler.open(){
                            let querySQL = "SELECT id, invitationName FROM INVITATION"
                            let results:FMResultSet? = databaseOpenHandler.socialdiningDB!.executeQuery(querySQL, withArgumentsInArray: nil)
                            while results?.next() == true {
                                let localInvitation: Invitation = Invitation()
                                localInvitation.id = results!.stringForColumn("id")
                                localInvitation.invitationName = results!.stringForColumn("invitationName")
                                
                                localInvitations.append(localInvitation)
                            }
                            /*Adding invitations to local database*/
                            for serverInvitation in serverInvitations{
                                var foundFlag = false
                                for localInvitation in localInvitations{
                                    if localInvitation.id! == serverInvitation.id!{
                                        foundFlag = true
                                    }
                                }
                                if !foundFlag{
                                    let invitationName = serverInvitation.invitationName!
                                    let escapedInvitationName = invitationName.stringByReplacingOccurrencesOfString("'", withString: "''")
                                    NSLog("\(self.TAG): DB INSERT: new invitation")
                                    let insertInvitationSQL = "INSERT INTO INVITATION (id, invitationName, hostId) VALUES ('\(serverInvitation.id!)', '\(escapedInvitationName)', '\(serverInvitation.host!.id!)')"
                                    let resultInvitation = databaseOpenHandler.socialdiningDB!.executeUpdate(insertInvitationSQL, withArgumentsInArray: nil)
                                    if !resultInvitation {
                                        NSLog("\(self.TAG): New Invitation: DB INSERT: Error: \(databaseOpenHandler.socialdiningDB!.lastErrorMessage())")
                                    } else {
                                        NSLog("\(self.TAG): DB INSERT: New Invitation: Invitation: \(serverInvitation.invitationName!) was successfuly added to database")
                                        /*Fire notification about this new invitation*/
                                        notificationHandler.fireNotification("New invitation: \(serverInvitation.invitationName!)", alertAction: "open")
                                    }
                                    /*Adding final date if it is already set in this new invitation*/
                                    if let finalDate = serverInvitation.eventDate{
                                        let updateEventDateSQL = "UPDATE INVITATION SET eventDate = '\(finalDate.timeIntervalSince1970)' WHERE id='\(serverInvitation.id!)'"
                                        let resultEventDate = databaseOpenHandler.socialdiningDB!.executeUpdate(updateEventDateSQL, withArgumentsInArray: nil)
                                        if !resultEventDate {
                                            NSLog("\(self.TAG): DB INSERT: New Invitation: Error: \(databaseOpenHandler.socialdiningDB!.lastErrorMessage())")
                                        } else {
                                            NSLog("\(self.TAG): DB INSERT: New Invitation: Final Date: \(finalDate) for Invitation: \(serverInvitation.invitationName!) was successfuly added to the database.")
                                        }
                                    }
                                    /*Adding final place if it is already set in this new invitation*/
                                    if let finalPlace = serverInvitation.eventPlace{
                                        let updateEventPlaceSQL = "UPDATE INVITATION SET eventPlace = '\(finalPlace.id!)' WHERE id='\(serverInvitation.id!)'"
                                        let resultEventPlace = databaseOpenHandler.socialdiningDB!.executeUpdate(updateEventPlaceSQL, withArgumentsInArray: nil)
                                        if !resultEventPlace {
                                            NSLog("\(self.TAG): DB INSERT: New Invitation: Error: \(databaseOpenHandler.socialdiningDB!.lastErrorMessage())")
                                        } else {
                                            NSLog("\(self.TAG): DB INSERT: New Invitation: Final Place: \(finalPlace.name!) for Invitation: \(serverInvitation.invitationName!) was successfuly added to the database.")
                                        }
                                    }
                                    /*Adding possible invitation dates*/
                                    if let possibleInvitationDates = serverInvitation.possibleInvitationDates{
                                        for possibleInvitationDate in possibleInvitationDates{
                                            let insertPossibleInvitationDateSQL = "INSERT INTO POSSIBLE_INVITATION_DATE (id, inviteid, eventDate) VALUES ('\(possibleInvitationDate.id!)', '\(serverInvitation.id!)','\(possibleInvitationDate.eventDate!.timeIntervalSince1970)')"
                                            let resultPossibleInvitationDate = databaseOpenHandler.socialdiningDB!.executeUpdate(insertPossibleInvitationDateSQL, withArgumentsInArray: nil)
                                            if !resultPossibleInvitationDate {
                                                NSLog("\(self.TAG): DB INSERT: New Invitation: Error: \(databaseOpenHandler.socialdiningDB!.lastErrorMessage())")
                                            } else {
                                                NSLog("\(self.TAG): DB INSERT: New Invitation: Date: \(possibleInvitationDate.eventDate!) Invitation: \(serverInvitation.invitationName!) was successfuly added to database")
                                            }
                                        }
                                    }
                                    /*Adding participants*/
                                    if let participants = serverInvitation.participants{
                                        for participant in participants{
                                            let insertParticipantSQL = "INSERT INTO PARTICIPANT (id, name, inviteid, userProfileImageUrl) VALUES ('\(participant.id!)', '\(participant.name!)', '\(serverInvitation.id!)', '\(participant.userProfileImageUrl!)')"
                                            let resultParticipant = databaseOpenHandler.socialdiningDB!.executeUpdate(insertParticipantSQL, withArgumentsInArray: nil)
                                            if !resultParticipant {
                                                NSLog("\(self.TAG): DB INSERT: New Invitation: Error: \(databaseOpenHandler.socialdiningDB!.lastErrorMessage())")
                                            } else {
                                                NSLog("\(self.TAG): DB INSERT: New Invitation: Participant: \(participant.name!) Invitation: \(serverInvitation.invitationName!) was successfuly added to database")
                                            }
                                        }
                                    }
                                    /*Adding host as one of the participants*/
                                    if let host = serverInvitation.host{
                                        let insertHostSQL = "INSERT INTO PARTICIPANT (id, name, inviteid, userProfileImageUrl) VALUES ('\(host.id!)', '\(host.name!)', '\(serverInvitation.id!)', '\(host.userProfileImageUrl!)')"
                                        let resultHost = databaseOpenHandler.socialdiningDB!.executeUpdate(insertHostSQL, withArgumentsInArray: nil)
                                        if !resultHost {
                                            NSLog("\(self.TAG): DB INSERT: New Invitation: Error: \(databaseOpenHandler.socialdiningDB!.lastErrorMessage())")
                                        } else {
                                            NSLog("\(self.TAG): DB INSERT: New Invitation: Participant: \(serverInvitation.host!.name!) Invitation: \(serverInvitation.invitationName!) was successfuly added to database")
                                        }
                                    }
                                    
                                    /*Adding places*/
                                    if let places = serverInvitation.possiblePlaces{
                                        for place in places{
                                            /*Escaping single quote with another for place name to allow adding to SQLite DB*/
                                            let placeName = place.name!
                                            let escapedPlaceName = placeName.stringByReplacingOccurrencesOfString("'", withString: "''")
                                            
                                            let insertPlaceSQL = "INSERT INTO PLACE (id, name, inviteid, place_id, vicinity, description, userId) VALUES ('\(place.id!)', '\(escapedPlaceName)', '\(serverInvitation.id!)', '\(place.placeId!)', '\(place.formattedAddress!)', '\(place.desc!)', '\(place.userId!)')"
                                            
                                            NSLog("\(self.TAG): address before INSERT \(place.formattedAddress!)")
                                            
                                            

                                            let resultPlace = databaseOpenHandler.socialdiningDB!.executeUpdate(insertPlaceSQL, withArgumentsInArray: nil)
                                            if !resultPlace {
                                                NSLog("\(self.TAG): DB INSERT: New Invitation: Error: \(databaseOpenHandler.socialdiningDB!.lastErrorMessage())")
                                            } else {
                                                NSLog("\(self.TAG): DB INSERT: New Invitation: Place: \(place.name!) Invitation: \(serverInvitation.invitationName!) was successfuly added to database")
                                            }
                                        }
                                    }
                                    
                                    /*If members>=2 and user is the host, add members as group to the DB ONLY if the group doesn't exist in the DB*/
                                    /*also don't add duplicate groups*/
                                    if let host = serverInvitation.host{
                                        if let participants = serverInvitation.participants{
                                            /*Checking group size and being the host*/
                                            if(participants.count>=2 && host.id==id){
                                                /*Compare group list with history of groups in DB before insert in the database*/
                                                var newListSet = Set<String>()
                                                for participant in participants{
                                                    newListSet.insert(participant.facebookId!)
                                                }
                                                var newListFound = false
                                                let queryGrouplistsSQL = "SELECT list, inviteid FROM GROUPLIST"
                                                let resultsGrouplists:FMResultSet? = databaseOpenHandler.socialdiningDB!.executeQuery(queryGrouplistsSQL, withArgumentsInArray: nil)
                                                while resultsGrouplists?.next() == true {
                                                    let existingList = resultsGrouplists!.stringForColumn("list")
                                                    let existingListSet = Set(existingList.characters.split{$0 == "-"}.map(String.init))
                                                    if(existingListSet.elementsEqual(newListSet)){
                                                        newListFound = true
                                                        let updateGroupTitleSQL = "UPDATE GROUPLIST SET invitationName = '\(serverInvitation.invitationName!)' WHERE inviteid='\(resultsGrouplists!.stringForColumn("inviteid"))'"
                                                        let resultUpdateGroupTitle = databaseOpenHandler.socialdiningDB!.executeUpdate(updateGroupTitleSQL, withArgumentsInArray: nil)
                                                        if !resultUpdateGroupTitle {
                                                            NSLog("\(self.TAG): DB UPDATE: UPDATE GROUP: Error: \(databaseOpenHandler.socialdiningDB!.lastErrorMessage())")
                                                        } else {
                                                            NSLog("\(self.TAG): DB UPDATE: UPDATE GROUP: Group title for Invitation: \(serverInvitation.invitationName!) was successfuly updated to the database.")
                                                        }
                                                        
                                                    }
                                                }
                                                /*Only add group if it doesn't exist in the DB*/
                                                if !newListFound{
                                                    var membersFacebookIds = ""
                                                    var membersNames = ""
                                                    for participant in participants{
                                                        membersFacebookIds+=participant.facebookId!+"-"
                                                        membersNames+=participant.name!+" "
                                                    }
                                                    let insertGroupSQL = "INSERT INTO GROUPLIST (list, names, inviteid, invitationName) VALUES ('\(membersFacebookIds)', '\(membersNames)', '\(serverInvitation.id!)', '\(serverInvitation.invitationName!)')"
                                                    let resultGroup = databaseOpenHandler.socialdiningDB!.executeUpdate(insertGroupSQL, withArgumentsInArray: nil)
                                                    if !resultGroup {
                                                        NSLog("\(self.TAG): DB INSERT: New Invitation: Error: \(databaseOpenHandler.socialdiningDB!.lastErrorMessage())")
                                                    } else {
                                                        NSLog("\(self.TAG): DB INSERT: New Invitation: Group: \(membersFacebookIds) Invitation: \(serverInvitation.invitationName!) was successfuly added to database")
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    
                                }
                            }
                        }
                        /*Refresh invitation listing in UI*/
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            NSNotificationCenter.defaultCenter().postNotificationName("redrawInvitationListID", object: nil)
                        })
                    }//else
                }//httpGET
            }//if let userDic
        }//if reachabilityStatus
    }
    
    func debugRequest(request: NSMutableURLRequest){
        print("Debug information for URL request: ")
        print(request.allHTTPHeaderFields)
        let body = NSString(data: request.HTTPBody!, encoding: NSUTF8StringEncoding)!
        print(body)
    }
    
    func convertJsonToArrayOfInvitations(serverInvitationsDataString: NSString)->[Invitation]{
        
        var serverInvitations = [Invitation]()
        let serverInvitationsData = serverInvitationsDataString.dataUsingEncoding(NSUTF8StringEncoding)
        let json = JSON(data: serverInvitationsData!)
        if let jsonArray = json.array{
            for invitationJson in jsonArray{
                let invitation = Mapper<Invitation>().map(invitationJson.description)
                serverInvitations.append(invitation!)
            }
        }
        print("Parsed invitations from server \(serverInvitations.count)")
        return serverInvitations
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
    
    func sychronizeInvitationWithServerById(inviteid: String){
        NSLog("\(self.TAG): Start: Update invitation information: \(inviteid)")
        if reachabilityStatus == kREACHABLEWITHWIFI || reachabilityStatus == kREACHABLEWITHWWAN{
            
            let invitationInfoURL = Config.SERVER_URL+"/invitations/\(inviteid)"
            let request = NSMutableURLRequest(URL: NSURL(string: invitationInfoURL)!)
            NSLog("\(self.TAG): HttpPost: Update invitation information")
            httpGet(request){
                (data, error) -> Void in
                if error != nil{
                    print(error)
                } else{
                    let invitation = self.convertJsonToInvitation(data)
                    self.syncInvitationWithLocalDB(invitation)
                    ChangeIconVisible().checkChangeIconVisible(inviteid)
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        NSNotificationCenter.defaultCenter().postNotificationName("redrawInvitationDetailsScreen", object: nil)
                        NSNotificationCenter.defaultCenter().postNotificationName("redrawInvitationListID", object: nil)
                        
                        
                    })
                }
            }
            
        }//if reachabilityStatus
    }
    
    func syncInvitationWithLocalDB(serverInvitation: Invitation){
        if databaseOpenHandler.open(){
            NSLog("\(self.TAG): Start: syncInvitationWithLocalDB")
            /*Ensure that the invitation actually exists in local DB before synchronization*/
            if databaseOpenHandler.open(){
                let inviteid = serverInvitation.id!
                let querySQL = "SELECT id, invitationName FROM INVITATION WHERE id='\(inviteid)'"
                let invitationResults:FMResultSet? = databaseOpenHandler.socialdiningDB!.executeQuery(querySQL, withArgumentsInArray: nil)
                var count: Int = Int()
                while invitationResults?.next() == true {
                    count++
                }
                if count != 0{
                    /*Synchronizing possibleInvitationDates objects*/
                    /*First, get all local Possible Invitation Dates*/
                    var localPossibleInvitationDatesIds: [String] = [String]()
                    let queryPossibleInvitationDatesSQL = "SELECT id, inviteid, eventDate FROM POSSIBLE_INVITATION_DATE WHERE inviteid='\(serverInvitation.id!)'"
                    let resultsPossibleInvitationDates:FMResultSet? = databaseOpenHandler.socialdiningDB!.executeQuery(queryPossibleInvitationDatesSQL, withArgumentsInArray: nil)
                    while resultsPossibleInvitationDates?.next() == true {
                        let id = resultsPossibleInvitationDates!.stringForColumn("id")
                        localPossibleInvitationDatesIds.append(id)
                    }
                    /*Add possible invitation dates that are on server but not local*/
                    if let serverPossibleInvitationDates = serverInvitation.possibleInvitationDates{
                        //Match possibeInvitationDates from server with local possibleInvitationDates
                        //and only add dates if they don't exist locally
                        /*Adding new PossibleInvtationDates*/
                        for serverPossibleInvitationDate in serverPossibleInvitationDates{
                            var foundFlag = false
                            for localPossibleInvitationDateId in localPossibleInvitationDatesIds{
                                if localPossibleInvitationDateId == serverPossibleInvitationDate.id!{
                                    foundFlag = true
                                }
                            }
                            if !foundFlag{
                                NSLog("\(self.TAG): DB INSERT: possibleInvitationDate")
                                let insertPossibleInvitationDateSQL = "INSERT INTO POSSIBLE_INVITATION_DATE (id, inviteid, eventDate) VALUES ('\(serverPossibleInvitationDate.id!)', '\(serverInvitation.id!)','\(serverPossibleInvitationDate.eventDate!.timeIntervalSince1970)')"
                                let resultPossibleInvitationDate = databaseOpenHandler.socialdiningDB!.executeUpdate(insertPossibleInvitationDateSQL, withArgumentsInArray: nil)
                    
                                if !resultPossibleInvitationDate {
                                    NSLog("\(self.TAG): DB INSERT: Error: \(databaseOpenHandler.socialdiningDB!.lastErrorMessage())")
                                } else {
                                    NSLog("\(self.TAG): DB INSERT: Date: \(serverPossibleInvitationDate.eventDate!) Invitation: \(serverInvitation.invitationName!) was successfuly added to database.")
                                    /*Fire notification about this new PossibleInvitationDate*/
                                    notificationHandler.fireNotification("\(serverInvitation.invitationName!): newly suggested meeting time!", alertAction: "open")
                                }
                            }
                        }
                    }
                    /*Deleting removed PossibleInvitationDates that are local but not coming from server*/
                    for localPossibleInvitationDateId in localPossibleInvitationDatesIds{
                        var foundFlag = false
                        if let serverPossibleInvitationDates = serverInvitation.possibleInvitationDates{
                            for serverPossibleInvitationDate in serverPossibleInvitationDates{
                                if (localPossibleInvitationDateId == serverPossibleInvitationDate.id){
                                    foundFlag = true
                                }
                            }
                        }
                        if !foundFlag{
                            NSLog("\(self.TAG): DB DEL: possibleInvitationDate")
                            let deletePossibleInvitationDateSQL = "DELETE FROM POSSIBLE_INVITATION_DATE WHERE id='\(localPossibleInvitationDateId)' AND inviteid='\(serverInvitation.id!)'"
                            let resultDeletePossibleInvitationDate = databaseOpenHandler.socialdiningDB!.executeUpdate(deletePossibleInvitationDateSQL, withArgumentsInArray: nil)
                            if !resultDeletePossibleInvitationDate {
                                NSLog("\(self.TAG): DB DEL: Error: \(databaseOpenHandler.socialdiningDB!.lastErrorMessage())")
                            } else {
                                NSLog("\(self.TAG): DB DEL: PossibleInvitationDate: \(localPossibleInvitationDateId) Invitation: \(serverInvitation.id!) was successfuly deleted from database")
                            }
                        }
                    }
                    /*Synchronizing places objects*/
                    /*First, get all local Possible Places*/
                    var localPlacesIds: [String] = [String]()
                    var localPlaceTitles: [String] = [String]()
                    let queryPlacesSQL = "SELECT id, name, inviteid, place_id FROM PLACE WHERE inviteid='\(serverInvitation.id!)'"
                    let resultsPlaces:FMResultSet? = databaseOpenHandler.socialdiningDB!.executeQuery(queryPlacesSQL, withArgumentsInArray: nil)
                    while resultsPlaces?.next() == true {
                        let id = resultsPlaces!.stringForColumn("id")
                        let name = resultsPlaces!.stringForColumn("name")
                        localPlacesIds.append(id)
                        localPlaceTitles.append(name)
                    }
                    if let serverPlaces = serverInvitation.possiblePlaces{
                        //Match places from server with local possibleInvitationDates
                        //and only add places if they don't exist locally
                        /*Adding new Places*/
                        for serverPlace in serverPlaces{
                            var foundFlag = false
                            for localPlaceId in localPlacesIds{
                                if localPlaceId == serverPlace.id{
                                    foundFlag = true
                                }
                            }
                            if !foundFlag{
                                /*Escaping single quote with another for place name to allow adding to SQLite DB*/
                                let placeName = serverPlace.name!
                                let escapedPlaceName = placeName.stringByReplacingOccurrencesOfString("'", withString: "''")
                                NSLog("\(self.TAG): DB INSERT: place")

                                let insertPlaceSQL = "INSERT INTO PLACE (id, name, inviteid, place_id, vicinity, description, userId) VALUES ('\(serverPlace.id!)', '\(escapedPlaceName)', '\(serverInvitation.id!)','\(serverPlace.placeId!)','\(serverPlace.formattedAddress!)', '\(serverPlace.desc!)', '\(serverPlace.userId!)')"

                                if serverPlace.formattedAddress == nil{
                                    serverPlace.formattedAddress = ""
                                }
                                                                let resultPlace = databaseOpenHandler.socialdiningDB!.executeUpdate(insertPlaceSQL, withArgumentsInArray: nil)
                        
                                if !resultPlace {
                                    NSLog("\(self.TAG): DB INSERT: Error: \(databaseOpenHandler.socialdiningDB!.lastErrorMessage())")
                                } else {
                                    NSLog("\(self.TAG): DB INSERT: Place: \(serverPlace.name!) Invitation: \(serverInvitation.invitationName!) was successfuly added to database")
                                    /*Fire notification about this new Place*/
                                    notificationHandler.fireNotification("\(serverInvitation.invitationName!): newly suggested meeting place!", alertAction: "open")
                                }
                            }
                        }
                    }
                    /*Deleting removed Places*/
                    for localPlaceId in localPlacesIds{
                        var foundFlag = false
                        if let serverPlaces = serverInvitation.possiblePlaces{
                            for serverPlace in serverPlaces{
                                if (localPlaceId == serverPlace.id){
                                    foundFlag = true
                                }
                            }
                        }
                        if !foundFlag{
                            NSLog("\(self.TAG): DB DEL: place")
                            let deletePlaceSQL = "DELETE FROM PLACE WHERE id='\(localPlaceId)' AND inviteid='\(serverInvitation.id!)'"
                            let resultDeletePlace = databaseOpenHandler.socialdiningDB!.executeUpdate(deletePlaceSQL, withArgumentsInArray: nil)
                            if !resultDeletePlace {
                                NSLog("\(self.TAG): DB DEL: Error: \(databaseOpenHandler.socialdiningDB!.lastErrorMessage())")
                            } else {
                                NSLog("\(self.TAG): DB DEL: Place: \(localPlaceId) Invitation: \(serverInvitation.id!) was successfuly deleted from database")
                            }
                        }
                    }
                    /*updating Place Titles*/
                    var index = 0
                    for placeId in localPlacesIds{
                        if let serverPlaces = serverInvitation.possiblePlaces{
                            for serverPlace in serverPlaces{
                                if (placeId == serverPlace.id! && localPlaceTitles[index] != serverPlace.name!){
                                    NSLog("\(self.TAG): DB UPDATE: place")
                                    let updatePlaceTitleSQL = "UPDATE PLACE SET name = '\(serverPlace.name!)' WHERE id='\(serverPlace.id!)'"
                                    let resultPlace = databaseOpenHandler.socialdiningDB!.executeUpdate(updatePlaceTitleSQL, withArgumentsInArray: nil)
                                    
                                    if !resultPlace {
                                        NSLog("\(self.TAG): DB UPDATE: Error: \(databaseOpenHandler.socialdiningDB!.lastErrorMessage())")
                                    } else {
                                        NSLog("\(self.TAG): DB UPDATE: Place: \(serverPlace.name!) Invitation: \(serverInvitation.invitationName!) was successfuly added to database")
                                        /*Fire notification about this new Place*/
                                        notificationHandler.fireNotification("\(serverInvitation.invitationName!): Successfully editing the title!", alertAction: "open")
                                    }
                                    
                                }
                            }
                        }
                        index += 1
                    }
                
            
                    /*Synchronizing particiapants objects*/
                    
                    //Match possibeInvitationDates from server with local possibleInvitationDates
                    //and only add places if they don't exist locally
                    var localParticipantsIds: [String] = [String]()
                    let querySQL = "SELECT id, name, inviteid FROM PARTICIPANT WHERE inviteid='\(serverInvitation.id!)'"
                    let results:FMResultSet? = databaseOpenHandler.socialdiningDB!.executeQuery(querySQL, withArgumentsInArray: nil)
                    while results?.next() == true {
                        let id = results!.stringForColumn("id")
                        localParticipantsIds.append(id)
                    }
                    if let serverParticipants = serverInvitation.participants{
                        /*Adding new particiapnts*/
                        for serverParticipant in serverParticipants{
                            var foundFlag = false
                            for localParticipantId in localParticipantsIds{
                                if localParticipantId == serverParticipant.id{
                                    foundFlag = true
                                }
                            }
                            if !foundFlag{
                                /*Escaping single quote with another for place name to allow adding to SQLite DB*/
                                let participantName = serverParticipant.name!
                                let escapedParticipantName = participantName.stringByReplacingOccurrencesOfString("'", withString: "''")
                                NSLog("\(self.TAG): DB INSERT: Participant")
                                let insertParticipantSQL = "INSERT INTO PARTICIPANT (id, name, inviteid, userProfileImageUrl) VALUES ('\(serverParticipant.id!)', '\(escapedParticipantName)', '\(serverInvitation.id!)', '\(serverParticipant.userProfileImageUrl!)')"
                                let resultParticipant = databaseOpenHandler.socialdiningDB!.executeUpdate(insertParticipantSQL, withArgumentsInArray: nil)
                        
                                if !resultParticipant {
                                    NSLog("\(self.TAG): DB INSERT: Error: \(databaseOpenHandler.socialdiningDB!.lastErrorMessage())")
                                } else {
                                    NSLog("\(self.TAG): DB INSERT: Participant: \(serverParticipant.name!) Invitation: \(serverInvitation.invitationName!) was successfuly added to database")
                                    /*Fire notification about this new Participant*/
                                    notificationHandler.fireNotification("\(serverInvitation.invitationName!): a new friend was added to the invitation!", alertAction: "open")
                                }
                            }
                        }
                    }
                
                    let hostUserId = serverInvitation.host?.id!
                    /*Deleting removed participants*/
                    for localParticipantId in localParticipantsIds{
                        if  localParticipantId != hostUserId{
                            var foundFlag = false
                            if let serverParticipants = serverInvitation.participants{
                                for serverParticipant in serverParticipants{
                                    if (localParticipantId == serverParticipant.id){
                                        foundFlag = true
                                    }
                                }
                            }
                            if !foundFlag{
                                NSLog("\(self.TAG): DB DEL: Participant")
                                let deleteParticipantSQL = "DELETE FROM PARTICIPANT WHERE id='\(localParticipantId)' AND inviteid='\(serverInvitation.id!)'"
                                let resultDeleteParticipant = databaseOpenHandler.socialdiningDB!.executeUpdate(deleteParticipantSQL, withArgumentsInArray: nil)
                                if !resultDeleteParticipant {
                                    NSLog("\(self.TAG): DB DEL: Error: \(databaseOpenHandler.socialdiningDB!.lastErrorMessage())")
                                } else {
                                    NSLog("\(self.TAG): DB DEL: Participant: \(localParticipantId) Invitation: \(serverInvitation.id!) was successfuly deleted from database")
                                }
                            }
                        }
                    }
                    
                    /*Synchronizing final date*/
                    if let serverEventDate = serverInvitation.eventDate{
                        NSLog("\(self.TAG): DB UPDATE: FINAL DATE: Received final date from server: \(serverInvitation.eventDate!)")
                        let updateEventDateSQL = "UPDATE INVITATION SET eventDate = '\(serverEventDate.timeIntervalSince1970)' WHERE id='\(serverInvitation.id!)'"
                        let resultEventDate = databaseOpenHandler.socialdiningDB!.executeUpdate(updateEventDateSQL, withArgumentsInArray: nil)
                        if !resultEventDate {
                            NSLog("\(self.TAG): DB UPDATE: FINAL DATE: Error: \(databaseOpenHandler.socialdiningDB!.lastErrorMessage())")
                        } else {
                            NSLog("\(self.TAG): DB UPDATE: FINAL DATE: Final Date: \(serverEventDate) for Invitation: \(serverInvitation.invitationName) was successfuly added to the database.")
                            /*Fire notification about posted Final date*/
                            notificationHandler.fireNotification("\(serverInvitation.invitationName!): final meeting time was set by the host!", alertAction: "open")
                        }
                    }
                    /*Synchronizing final place*/
                    if let serverEventPlace = serverInvitation.eventPlace{
                        NSLog("\(self.TAG): DB UPDATE: FINAL PLACE: Received final place from server")
                        let updateEventPlaceSQL = "UPDATE INVITATION SET eventPlace = '\(serverEventPlace.id!)' WHERE id='\(serverInvitation.id!)'"
                        let resultEventPlace = databaseOpenHandler.socialdiningDB!.executeUpdate(updateEventPlaceSQL, withArgumentsInArray: nil)
                        if !resultEventPlace {
                            NSLog("\(self.TAG): DB UPDATE: FINAL PLACE: Error: \(databaseOpenHandler.socialdiningDB!.lastErrorMessage())")
                        } else {
                            NSLog("\(self.TAG): DB UPDATE: FINAL PLACE: Final Place: \(serverEventPlace.name!) for Invitation: \(serverInvitation.invitationName) was successfuly added to the database.")
                            /*Fire notification about posted Final place*/
                            notificationHandler.fireNotification("\(serverInvitation.invitationName!): final meeting location was set by the host!", alertAction: "open")
                        }
                    }
                }
            }
        }
    }
    
    /*This method sets the archived field in local DB for the invitaiton to true*/
    /*Archived invitations will not be presented to the user in the invitation listing*/
    func archiveInvitationLocally(invitation: Invitation){
        NSLog("\(self.TAG): DB UPDATE: Delete Invitation: Start archving invitation locally...")
        if databaseOpenHandler.open(){
            let updateArchivedSQL = "UPDATE INVITATION SET archived = '\(1)' WHERE id='\(invitation.id!)'"
            let resultArchived = databaseOpenHandler.socialdiningDB!.executeUpdate(updateArchivedSQL, withArgumentsInArray: nil)
            if !resultArchived {
                NSLog("\(self.TAG): DB UPDATE: Delete Invitation: Error: \(databaseOpenHandler.socialdiningDB!.lastErrorMessage())")
            } else {
                NSLog("\(self.TAG): DB UPDATE: Delete Invitation: Invitation: \(invitation.invitationName!) was successfuly archived in the database.")
            }
        }
        /*Refresh invitation listing in UI*/
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            NSNotificationCenter.defaultCenter().postNotificationName("redrawInvitationListID", object: nil)
        })
    }
    
    func convertJsonToInvitation(serverInvitationDataString: NSString)->Invitation{
        let serverInvitationData = serverInvitationDataString.dataUsingEncoding(NSUTF8StringEncoding)
        let invitationJson = JSON(data: serverInvitationData!)
        let invitation = Mapper<Invitation>().map(invitationJson.description)
        
        return invitation!
    }
}
