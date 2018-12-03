var placeVoteDataManager: PlaceVoteDataManager = PlaceVoteDataManager()

import UIKit
import ObjectMapper

class PlaceVoteDataManager: NSObject {
    
    let TAG = "PlaceVoteDataManager"
    
    /*A method to post a new PlaceVote to an Invitation*/
    func postPlaceVoteToInvitationOnServer(newPlaceVote: PlaceVote, invitationID: String, hostId: String, hostName: String){
        NSLog("\(self.TAG): Start: Post Possible Place Vote")
        NSLog("Post for place: \(newPlaceVote.place?.name) to invite: \(invitationID) ")
        let newPlaceVoteParameters: NSMutableDictionary = NSMutableDictionary()
        /*preparing host for posting*/
        let hostDic: NSMutableDictionary = NSMutableDictionary()
        hostDic.setObject(hostId, forKey: "id")
        hostDic.setObject(hostName, forKey: "name")
        newPlaceVoteParameters.setObject(hostDic, forKey: "user")
        
        /*preparing place for posting*/
        let placeDic:NSMutableDictionary = NSMutableDictionary()
        placeDic.setObject(newPlaceVote.place!.id!, forKey: "id")
        placeDic.setObject(newPlaceVote.place!.name!, forKey: "name")
        placeDic.setObject(newPlaceVote.place!.formattedAddress!, forKey: "vicinity")
        newPlaceVoteParameters.setObject(placeDic, forKey: "place")
        
        /*preparing invitation for posting*/
        let invitationDic: NSMutableDictionary = NSMutableDictionary()
        invitationDic.setObject(invitationID, forKey: "id")
        newPlaceVoteParameters.setObject(invitationDic, forKey: "invitation")
        
        /*Post the new request to the server*/
        NSLog("\(self.TAG): HttpPost: Post Possible Place Vote")
        let request = NSMutableURLRequest(URL: NSURL(string: Config.SERVER_URL+"/placeVotes")!)
        let session = NSURLSession.sharedSession()
        request.HTTPMethod = "POST"
        var err: NSError?
        do {
            request.HTTPBody = try NSJSONSerialization.dataWithJSONObject(newPlaceVoteParameters, options: [])
        } catch let error as NSError {
            err = error
            NSLog("\(self.TAG): HttpPost: Post Possible Place Vote: Error: \(err?.localizedDescription)")
            request.HTTPBody = nil
        }
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let task = session.dataTaskWithRequest(request, completionHandler: {data, response, error -> Void in
            do {
                let _ = try NSJSONSerialization.JSONObjectWithData(data!, options: [])
                NSLog("\(self.TAG): HttpPost: Post Possible Place Vote: Successfuly posted new place vote to server...")
            } catch {
                // failure
                NSLog("\(self.TAG): HttpPost: Post Possible Place Vote: Error: \((error as NSError).localizedDescription)")
            }
            
        })
        task.resume()
    }
    
    /*A method that deletes an existing PlaceVote from an Invitation*/
    func deletePlaceVoteFromInvitationFromServer(placeVote: PlaceVote, invitationID: String, hostId: String, hostName: String){
        NSLog("\(self.TAG): Start: Delete Possible Place Vote")
        NSLog("Delete vote for date: \(placeVote.place?.id) to invite: \(invitationID)")
        //To-do: the delete takes NO PARAMETER
        //It is only a call to "/possibleInvitationDateVotes/{voteid}"
        
        let voteid = placeVote.id!
        let deletePlaceVoteURL = Config.SERVER_URL+"/placeVotes/\(voteid)"
        let request = NSMutableURLRequest(URL: NSURL(string: deletePlaceVoteURL)!)
        request.HTTPMethod = "DELETE"
        NSLog("\(self.TAG): HttpDelete: Delete Possible Place Vote")
        httpGet(request){
            (data, error) -> Void in
            if error != nil{
                NSLog("\(self.TAG): HttpDelete: Delete Possible Place Vote: \(error)")
                print(error)
            } else{
                NSLog("\(self.TAG): HttpDelete: Delete Possible Place Vote: Successfully posted delete PlaceVote to server...")
            }
        }
        
    }
    
    func getListOfPlaceVotesForInvitationFromLocalDB(inviteid: NSString)->[PlaceVote]{
        var placeVotes: [PlaceVote] = [PlaceVote]()

        if databaseOpenHandler.open(){
            let queryPlaceVotesSQL = "SELECT id, inviteid, place_id, userid, facebookname FROM PLACE_VOTE WHERE inviteid='\(inviteid)'"
            let placeVoteResults:FMResultSet? = databaseOpenHandler.socialdiningDB!.executeQuery(queryPlaceVotesSQL, withArgumentsInArray: nil)
            while placeVoteResults?.next() == true {
                let placeVote: PlaceVote = PlaceVote()
                placeVote.id = placeVoteResults!.stringForColumn("id")
                let invitation: Invitation = Invitation()
                invitation.id = placeVoteResults!.stringForColumn("inviteid")
                placeVote.invitation = invitation
                let place: Restaurant = Restaurant()
                place.id = placeVoteResults!.stringForColumn("place_id")
                placeVote.place = place
                placeVote.userId = placeVoteResults!.stringForColumn("userid")
                placeVote.userName = placeVoteResults!.stringForColumn("facebookname")
                placeVotes.append(placeVote)
            }
        }
        return placeVotes
    }
    
    /*add flag indicates whether we are expecting new PlaceVote to add locally
    or we are expecting to delete local PlaceVote*/
    func sychronizeInvitationPlaceVotesWithServerById(inviteid: String, addFlag: Bool){
        NSLog("\(self.TAG): Start: Synchronize place votes for invitation")
        let invitationPlaceVotesInfoURL = Config.SERVER_URL+"/invitations/\(inviteid)/placeVotes"
        let request = NSMutableURLRequest(URL: NSURL(string: invitationPlaceVotesInfoURL)!)
        NSLog("\(self.TAG): HttpGet: Synchronize place votes for invitation")
        httpGet(request){
            (data, error) -> Void in
            if error != nil{
                NSLog("\(self.TAG): HttpGet: Synchronize place votes for invitation: \(error)")
                print(error)
            } else{
                let serverPlaceVotes = self.convertJsonToArrayOfPlaceVotes(data)
                if addFlag{
                    self.addNewPlaceVotesToLocalDB(serverPlaceVotes, inviteid: inviteid)
                }else{
                    self.deletePlaceVotesFromLocalDB(serverPlaceVotes, inviteid: inviteid)
                }
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    NSNotificationCenter.defaultCenter().postNotificationName("redrawInvitationDetailsScreen", object: nil)
                })
            }
        }
    }
    
    /*Method to add new PossibleInvitationDateVote from server to local DB in case a new GCM arrives for a new PossibleInvitationDateVote*/
    func addNewPlaceVotesToLocalDB(serverPlaceVotes: [PlaceVote], inviteid: String){
        
        if databaseOpenHandler.open(){
            var localPlaceVotesIds: [String] = [String]()
            var localCombinedIds: [String] = [String]()
            
            let querySQL = "SELECT id, inviteid, place_id, userid FROM PLACE_VOTE WHERE inviteid='\(inviteid)'"
            let results:FMResultSet? = databaseOpenHandler.socialdiningDB!.executeQuery(querySQL, withArgumentsInArray: nil)
            while results?.next() == true {
                let id = results!.stringForColumn("id")
                localPlaceVotesIds.append(id)
                
                
                let userid = results!.stringForColumn("userid")
                let placeId = results!.stringForColumn("place_id")
                let localCombinedId = userid + placeId
                localCombinedIds.append(localCombinedId)
            }
            /*if server PossibleInvitationDateVote is not found locally, add it to local DB*/
            for serverPlaceVote in serverPlaceVotes{
                
                var foundFlag = false
                var duplicateFlag = false
                
                for localPlaceVoteId in localPlaceVotesIds{
                    if localPlaceVoteId == serverPlaceVote.id!{
                        foundFlag = true
                        
                    }
                }
                
                for localCombinedId in localCombinedIds{
                    
                    let serverUserId = serverPlaceVote.userId!
                    let serverPlaceId = serverPlaceVote.place!.id!
                    let serverCombinedId = serverUserId + (serverPlaceId as String)
                    if localCombinedId == serverCombinedId{
                        duplicateFlag = true
                    }
                }
                
                
                if !foundFlag && !duplicateFlag{
                    NSLog("\(self.TAG): DB INSERT: Synchronize place votes for invitation")
                    let insertPlaceVoteSQL = "INSERT INTO PLACE_VOTE (id, inviteid, place_id, userid, facebookname) VALUES ('\(serverPlaceVote.id!)', '\(inviteid)', '\(serverPlaceVote.place!.id!)', '\(serverPlaceVote.userId!)', '\(serverPlaceVote.userName)')"
                    let resultAddPlaceVote = databaseOpenHandler.socialdiningDB!.executeUpdate(insertPlaceVoteSQL, withArgumentsInArray: nil)
                    if !resultAddPlaceVote {
                        NSLog("\(self.TAG): DB INSERT: Synchronize place votes for invitation: Error: \(databaseOpenHandler.socialdiningDB!.lastErrorMessage())")
                    } else {
                        NSLog("\(self.TAG): DB INSERT: Synchronize place votes for invitation: PlaceVote: \(serverPlaceVote.id) Invitation: \(inviteid) was successfuly added to database")
                    }
                }
            }
        }
    }
    
    /*Method to delete PossibleInvitationDateVote from local DB in case a new GCM arrives for a deleted PossibleInvitationDateVote*/
    func deletePlaceVotesFromLocalDB(serverPlaceVotes: [PlaceVote], inviteid: String){

        if databaseOpenHandler.open(){
            var localPlaceVotesIds: [String] = [String]()
            let querySQL = "SELECT id, inviteid, place_id FROM PLACE_VOTE WHERE inviteid='\(inviteid)'"
            let results:FMResultSet? = databaseOpenHandler.socialdiningDB!.executeQuery(querySQL, withArgumentsInArray: nil)
            while results?.next() == true {
                let id = results!.stringForColumn("id")
                localPlaceVotesIds.append(id)
            }
            /*if local PossibleInvitationDateVote is not found on server list, delete it from local DB*/
            for localPlaceVoteId in localPlaceVotesIds{
                var foundFlag = false
                for serverPlaceVote in serverPlaceVotes{
                    if serverPlaceVote.id! == localPlaceVoteId{
                        foundFlag = true
                    }
                }
                if !foundFlag{
                    NSLog("\(self.TAG): DB DEL: Synchronize place votes for invitation")
                    let deletePlaceVoteSQL = "DELETE FROM PLACE_VOTE WHERE id='\(localPlaceVoteId)'"
                    let resultDeletePlaceVote = databaseOpenHandler.socialdiningDB!.executeUpdate(deletePlaceVoteSQL, withArgumentsInArray: nil)
                    if !resultDeletePlaceVote {
                        NSLog("\(self.TAG): DB DEL: Synchronize place votes for invitation: Error: \(databaseOpenHandler.socialdiningDB!.lastErrorMessage())")
                    } else {
                        NSLog("\(self.TAG): DB DEL: Synchronize place votes for invitation: PlaceVote: \(localPlaceVoteId) Invitation: \(inviteid) was successfuly deleted from database")
                    }
                }
            }
            
        }
    }
    
    
    /*This new method for refreshing place votes from the server works based on the concept of deleting all local votes and replacing them*/
    /*with votes coming from the server. This is created to ensure that the user will eventually have a correct copy even if they drift a part*/
    /*from the copy coming from the server*/
    func copyInvitationPlaceVotesFromServerById(inviteid: String){
        NSLog("\(self.TAG): Start: Copy place votes for invitation")
        
        let invitationPlaceVotesInfoURL = Config.SERVER_URL+"/invitations/\(inviteid)/placeVotes"
        let request = NSMutableURLRequest(URL: NSURL(string: invitationPlaceVotesInfoURL)!)
        NSLog("\(self.TAG): HttpGet: Copy place votes for invitation")
        httpGet(request){
            (data, error) -> Void in
            if error != nil{
                NSLog("\(self.TAG): HttpGet: Copy place votes for invitation: \(error)")
                print(error)
            } else{
                let serverPlaceVotes = self.convertJsonToArrayOfPlaceVotes(data)
                self.flushPlaceVotesInLocalDBWithDateVotesFromServer(serverPlaceVotes, inviteid: inviteid)
            }
        }
        ChangeIconVisible().checkChangeIconVisible(inviteid)
    }
    
    func flushPlaceVotesInLocalDBWithDateVotesFromServer(serverPlaceVotes: [PlaceVote], inviteid: String){
        if databaseOpenHandler.open(){
            
            
            let lockDBPlaceVotesQueue = dispatch_queue_create("edu.colorado.edu.socialfusion.socialdining.placevote", nil)
            dispatch_sync(lockDBPlaceVotesQueue) {
                /*Step 1: Delete all local place votes for the invitation from the localDB*/
                NSLog("\(self.TAG): DB DELETE ALL: Synchronize place votes for invitation")
                let deleteAllPlaceVoteSQL = "DELETE FROM PLACE_VOTE WHERE inviteid='\(inviteid)'"
                let resultDeleteAllPlaceVote = databaseOpenHandler.socialdiningDB!.executeUpdate(deleteAllPlaceVoteSQL, withArgumentsInArray: nil)
                if !resultDeleteAllPlaceVote{
                    NSLog("\(self.TAG): DB DELETE ALL: Synchronize place votes for invitation: Error: \(databaseOpenHandler.socialdiningDB!.lastErrorMessage())")
                }else{
                    NSLog("\(self.TAG): DB DELETE ALL: Successfully deleted all local place votes for the invitation")
                }
            }
            dispatch_sync(lockDBPlaceVotesQueue) {
                /*Step 2: Add all server place votes to local DB*/
                for serverPlaceVote in serverPlaceVotes{
                    NSLog("\(self.TAG): DB INSERT: Synchronize place votes for invitation")
                    let insertPlaceVoteSQL = "INSERT INTO PLACE_VOTE (id, inviteid, place_id, userid, facebookname) VALUES ('\(serverPlaceVote.id!)', '\(inviteid)', '\(serverPlaceVote.place!.id!)', '\(serverPlaceVote.userId!)', '\(serverPlaceVote.userName)')"
                    let resultAddPlaceVote = databaseOpenHandler.socialdiningDB!.executeUpdate(insertPlaceVoteSQL, withArgumentsInArray: nil)
                    if !resultAddPlaceVote {
                        NSLog("\(self.TAG): DB INSERT: Synchronize place votes for invitation: Error: \(databaseOpenHandler.socialdiningDB!.lastErrorMessage())")
                    } else {
                        NSLog("\(self.TAG): DB INSERT: Synchronize place votes for invitation: PossibleInvitationDateVote: \(serverPlaceVote.id) Invitation: \(inviteid) was successfuly added to database")
                        
                    }
                }
                
                
                dispatch_sync(dispatch_get_main_queue(), { () -> Void in
                 NSNotificationCenter.defaultCenter().postNotificationName("redrawInvitationDetailsScreen", object: nil)
                })
            }
        }
    }
    
    func convertJsonToArrayOfPlaceVotes(serverPlaceVotesDataString: NSString)->[PlaceVote]{
        var serverPlaceVotes = [PlaceVote]()
        let serverPlaceVotesData = serverPlaceVotesDataString.dataUsingEncoding(NSUTF8StringEncoding)
        let json = JSON(data: serverPlaceVotesData!)
        if let jsonArray = json.array{
            NSLog("it is an array")
            for placeVoteJson in jsonArray{
                let placeVote = Mapper<PlaceVote>().map(placeVoteJson.description)
                serverPlaceVotes.append(placeVote!)
            }
        }
        return serverPlaceVotes
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
}
