var possibleInvitationDateVoteDataManager: PossibleInvitationDateVoteDataManager = PossibleInvitationDateVoteDataManager()

import UIKit
import ObjectMapper

class PossibleInvitationDateVoteDataManager: NSObject {
    
    let TAG = "PossibleInvitationDateVoteDataManager"
    
    /*A method that posts a new PossibleInvitationDateVote to an Invitation*/
    func postPossibleInvitationDateVoteToInvitationOnServer(newPossibleInvitationDateVote: PossibleInvitationDateVote, invitationID: String, hostId: String, hostName: String){
        NSLog("\(self.TAG): Start: Post Possible Invitation Date Vote")
        NSLog("Post vote for date: \(newPossibleInvitationDateVote.possibleInvitationDate?.eventDate) to invite: \(invitationID)")
        let newPossibleInvitationDateVoteParameters:  NSMutableDictionary = NSMutableDictionary()
        /*preparing host for posting*/
        let hostDic: NSMutableDictionary = NSMutableDictionary()
        hostDic.setObject(hostId, forKey: "id")
        hostDic.setObject(hostName, forKey: "name")
        newPossibleInvitationDateVoteParameters.setObject(hostDic, forKey: "user")
        
        /*preparing PossibleInvitationDate for posting */
        let possibleInvitationDateDic:NSMutableDictionary = NSMutableDictionary()
        possibleInvitationDateDic.setObject(newPossibleInvitationDateVote.possibleInvitationDate!.id!, forKey: "id")
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "EEE MMM dd HH:mm:ss z yyyy"
        let dateString = dateFormatter.stringFromDate(newPossibleInvitationDateVote.possibleInvitationDate!.eventDate!)
        possibleInvitationDateDic.setObject(dateString, forKey: "eventDate")
        newPossibleInvitationDateVoteParameters.setObject(possibleInvitationDateDic, forKey: "possibleInvitationDate")
        
        /*preparing Invitation for posting*/
        let invitationDic:NSMutableDictionary = NSMutableDictionary()
        invitationDic.setObject(invitationID, forKey: "id")
        newPossibleInvitationDateVoteParameters.setObject(invitationDic, forKey: "invitation")
        
        /*Post the new request to the server*/
        NSLog("\(self.TAG): HttpPost: Post Possible Invitation Date Vote")
        let request = NSMutableURLRequest(URL: NSURL(string: Config.SERVER_URL+"/possibleInvitationDateVotes")!)
        let session = NSURLSession.sharedSession()
        request.HTTPMethod = "POST"
        var err: NSError?
        do {
            request.HTTPBody = try NSJSONSerialization.dataWithJSONObject(newPossibleInvitationDateVoteParameters, options: [])
        } catch let error as NSError {
            err = error
            print("\(self.TAG): \(err?.localizedDescription)")
            request.HTTPBody = nil
        }
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let task = session.dataTaskWithRequest(request, completionHandler: {data, response, error -> Void in
            do {
                let _ = try NSJSONSerialization.JSONObjectWithData(data!, options: [])
                NSLog("\(self.TAG): HttpPost: Post Possible Invitation Date Vote: Successfuly posted Final Place to server...")
            } catch {
                // failure
                NSLog("\(self.TAG): HttpPost: Post Possible Invitation Date Vote: \((error as NSError).localizedDescription)")
            }
        })
        task.resume()
    }
    
    /*A method that deletes an existing PossibleInvitationDateVote from an Invitation*/
    func deletePossibleInvitationDateVoteFromInvitationOnServer(possibleInvitationDateVote: PossibleInvitationDateVote, invitationID: String, hostId: String, hostName: String){
        NSLog("\(self.TAG): Start: Delete Possible Invitation Date Vote")
        NSLog("Delete vote for date: \(possibleInvitationDateVote.possibleInvitationDate?.id) to invite: \(invitationID)")
        //To-do: the delete takes NO PARAMETER
        //It is only a call to "/possibleInvitationDateVotes/{voteid}"
        let voteid = possibleInvitationDateVote.id!
        let deletePossibleInvitationDateVoteURL = Config.SERVER_URL+"/possibleInvitationDateVotes/\(voteid)"
        let request = NSMutableURLRequest(URL: NSURL(string: deletePossibleInvitationDateVoteURL)!)
        request.HTTPMethod = "DELETE"
        NSLog("\(self.TAG): HttpDelete: Delete Possible Invitation Date Vote")
        httpGet(request){
            (data, error) -> Void in
            if error != nil{
                NSLog("\(self.TAG): HttpDelete: Delete Possible Invitation Date Vote: Error: \(error)")
                print(error)
            } else{
                NSLog("\(self.TAG): HttpDelete: Delete Possible Invitation Date Vote: Successfully posted delete PossibleInvitationDateVote to server...")
            }
        }

    }
    
    /*A method that gets all PossibleInvitationDateVotes for an invitation*/
    func getListOfPossibleInvitationDateVotesForInvitationFromLocalDB(inviteid: NSString)->[PossibleInvitationDateVote]{
        var possibleInvitationDateVotes: [PossibleInvitationDateVote] = [PossibleInvitationDateVote]()
        if databaseOpenHandler.open(){
            let queryPossibleInvitationDateVotesSQL = "SELECT id, inviteid, possible_invitation_date_id, userid, facebookname FROM POSSIBLE_INVITATION_DATE_VOTE WHERE inviteid='\(inviteid)'"
            let possibleInvitationDateVoteResults:FMResultSet? = databaseOpenHandler.socialdiningDB!.executeQuery(queryPossibleInvitationDateVotesSQL, withArgumentsInArray: nil)
            while possibleInvitationDateVoteResults?.next() == true {
                let possibleInvitationDateVote: PossibleInvitationDateVote = PossibleInvitationDateVote()
                possibleInvitationDateVote.id = possibleInvitationDateVoteResults!.stringForColumn("id")
                let invitation: Invitation = Invitation()
                invitation.id = possibleInvitationDateVoteResults!.stringForColumn("inviteid")
                possibleInvitationDateVote.invitation = invitation
                let possibleInvitationDate: PossibleInvitationDate = PossibleInvitationDate()
                possibleInvitationDate.id = possibleInvitationDateVoteResults!.stringForColumn("possible_invitation_date_id")
                possibleInvitationDateVote.possibleInvitationDate = possibleInvitationDate
                possibleInvitationDateVote.userId = possibleInvitationDateVoteResults!.stringForColumn("userid")
                possibleInvitationDateVote.userName = possibleInvitationDateVoteResults!.stringForColumn("facebookname")
                possibleInvitationDateVotes.append(possibleInvitationDateVote)
            }
        }
        return possibleInvitationDateVotes
    }
    
    /*add flag indicates whether we are expecting new PossibleInvitationDateVote to add locally
    or we are expecting to delete local PossibleInvitationDateVote*/
    func sychronizeInvitationDateVotesWithServerById(inviteid: String, addFlag: Bool){
        NSLog("\(self.TAG): Start: Synchronize date votes for invitation")
        let invitationDateVotesInfoURL = Config.SERVER_URL+"/invitations/\(inviteid)/possibleInvitationDateVotes"
        let request = NSMutableURLRequest(URL: NSURL(string: invitationDateVotesInfoURL)!)
        NSLog("\(self.TAG): HttpGet: Synchronize date votes for invitation")
        httpGet(request){
            (data, error) -> Void in
            if error != nil{
                NSLog("\(self.TAG): HttpGet: Synchronize date votes for invitation: \(error)")
                print(error)
            } else{
                let serverPossibleInvitationDateVotes = self.convertJsonToArrayOfPossibleInvitationDateVotes(data)
                if addFlag{
                    self.addNewPossibleInvitationDateVotesToLocalDB(serverPossibleInvitationDateVotes, inviteid: inviteid)
                }else{
                    self.deletePossibleInvitationDateVotesFromLocalDB(serverPossibleInvitationDateVotes, inviteid: inviteid)
                }
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    NSNotificationCenter.defaultCenter().postNotificationName("redrawInvitationDetailsScreen", object: nil)
                })
            }
        }
    }
    /*Method to add new PossibleInvitationDateVote from server to local DB in case a new GCM arrives for a new PossibleInvitationDateVote*/
    func addNewPossibleInvitationDateVotesToLocalDB(serverPossibleInvitationDateVotes: [PossibleInvitationDateVote], inviteid: String){
        if databaseOpenHandler.open(){
            var localPossibleInvitationDateVotesIds: [String] = [String]()
            var localCombinedIds: [String] = [String]()
            
            let querySQL = "SELECT id, inviteid, possible_invitation_date_id, userid FROM POSSIBLE_INVITATION_DATE_VOTE WHERE inviteid='\(inviteid)'"
            let results:FMResultSet? = databaseOpenHandler.socialdiningDB!.executeQuery(querySQL, withArgumentsInArray: nil)
            while results?.next() == true {
                let id = results!.stringForColumn("id")
                localPossibleInvitationDateVotesIds.append(id)
                
                let userid = results!.stringForColumn("userid")
                let possibleInvitationDateId = results!.stringForColumn("possible_invitation_date_id")
                let localCombinedId = userid + possibleInvitationDateId
                localCombinedIds.append(localCombinedId)
                
            }
            /*if server PossibleInvitationDateVote is not found locally, add it to local DB*/
            for serverPossibleInvitationDateVote in serverPossibleInvitationDateVotes{
                
                var foundFlag = false
                var duplicateFlag = false
                
                for localPossibleInvitationDateVoteId in localPossibleInvitationDateVotesIds{
                    if localPossibleInvitationDateVoteId == serverPossibleInvitationDateVote.id!{
                        foundFlag = true
                        
                    }
                }
                
                for localCombinedId in localCombinedIds{
                    
                    let serverUserId = serverPossibleInvitationDateVote.userId!
                    let serverPossibleInvitationDateId = serverPossibleInvitationDateVote.possibleInvitationDate!.id!
                    let serverCombinedId = serverUserId + (serverPossibleInvitationDateId as String)
                    if localCombinedId == serverCombinedId{
                            duplicateFlag = true
                    }
                }
                
                if !foundFlag && !duplicateFlag{
                    NSLog("\(self.TAG): DB INSERT: Synchronize date votes for invitation")
                    let insertPossibleInvitationDateVoteSQL = "INSERT INTO POSSIBLE_INVITATION_DATE_VOTE (id, inviteid, possible_invitation_date_id, userid, facebookname) VALUES ('\(serverPossibleInvitationDateVote.id!)', '\(inviteid)', '\(serverPossibleInvitationDateVote.possibleInvitationDate!.id!)', '\(serverPossibleInvitationDateVote.userId!)', '\(serverPossibleInvitationDateVote.userName)')"
                    let resultAddPossibleInvitationDateVote = databaseOpenHandler.socialdiningDB!.executeUpdate(insertPossibleInvitationDateVoteSQL, withArgumentsInArray: nil)
                    if !resultAddPossibleInvitationDateVote {
                        NSLog("\(self.TAG): DB INSERT: Synchronize date votes for invitation: Error: \(databaseOpenHandler.socialdiningDB!.lastErrorMessage())")
                    } else {
                        NSLog("\(self.TAG): DB INSERT: Synchronize date votes for invitation: PossibleInvitationDateVote: \(serverPossibleInvitationDateVote.id) Invitation: \(inviteid) was successfuly added to database")
                    }
                }
            }
        }
    }
    
    /*Method to delete PossibleInvitationDateVote from local DB in case a new GCM arrives for a deleted PossibleInvitationDateVote*/
    func deletePossibleInvitationDateVotesFromLocalDB(serverPossibleInvitationDateVotes: [PossibleInvitationDateVote], inviteid: String){

        if databaseOpenHandler.open(){
            var localPossibleInvitationDateVotesIds: [String] = [String]()
            let querySQL = "SELECT id, inviteid, possible_invitation_date_id FROM POSSIBLE_INVITATION_DATE_VOTE WHERE inviteid='\(inviteid)'"
            let results:FMResultSet? = databaseOpenHandler.socialdiningDB!.executeQuery(querySQL, withArgumentsInArray: nil)
            while results?.next() == true {
                let id = results!.stringForColumn("id")
                localPossibleInvitationDateVotesIds.append(id)
            }
            /*if local PossibleInvitationDateVote is not found on server list, delete it from local DB*/
            for localPossibleInvitationDateVoteId in localPossibleInvitationDateVotesIds{
                var foundFlag = false
                for serverPossibleInvitationDateVote in serverPossibleInvitationDateVotes{
                    if serverPossibleInvitationDateVote.id! == localPossibleInvitationDateVoteId{
                        foundFlag = true
                    }
                }
                if !foundFlag{
                    NSLog("\(self.TAG): DB DEL: Synchronize date votes for invitation")
                    let deletePossibleInvitationDateVoteSQL = "DELETE FROM POSSIBLE_INVITATION_DATE_VOTE WHERE id='\(localPossibleInvitationDateVoteId)'"
                    let resultDeletePossibleInvitationDateVote = databaseOpenHandler.socialdiningDB!.executeUpdate(deletePossibleInvitationDateVoteSQL, withArgumentsInArray: nil)
                    if !resultDeletePossibleInvitationDateVote {
                        NSLog("\(self.TAG): DB DEL: Synchronize date votes for invitation: Error: \(databaseOpenHandler.socialdiningDB!.lastErrorMessage())")
                    } else {
                        NSLog("\(self.TAG): DB DEL: Synchronize date votes for invitation: PossibleInvitationDateVote: \(localPossibleInvitationDateVoteId) Invitation: \(inviteid) was successfuly deleted from database")
                    }
                }
            }
            
        }
    }
    
    
    /*This new method for refreshing date votes from the server works based on the concept of deleting all local votes and replacing them*/
    /*with votes coming from the server. This is created to ensure that the user will eventually have a correct copy even if they drift a part*/
    /*from the copy coming from the server*/
    func copyInvitationDateVotesFromServerById(inviteid: String){
        NSLog("\(self.TAG): Start: Copy date votes for invitation")
        
        let invitationDateVotesInfoURL = Config.SERVER_URL+"/invitations/\(inviteid)/possibleInvitationDateVotes"
        let request = NSMutableURLRequest(URL: NSURL(string: invitationDateVotesInfoURL)!)
        NSLog("\(self.TAG): HttpGet: Copy date votes for invitation")
        httpGet(request){
            (data, error) -> Void in
            if error != nil{
                NSLog("\(self.TAG): HttpGet: Copy date votes for invitation: \(error)")
                print(error)
            } else{
                let serverPossibleInvitationDateVotes = self.convertJsonToArrayOfPossibleInvitationDateVotes(data)
                self.flushPossibleInvitationDateVotesInLocalDBWithDateVotesFromServer(serverPossibleInvitationDateVotes, inviteid: inviteid)
            }
        }
        ChangeIconVisible().checkChangeIconVisible(inviteid)
        
    }
    
    func flushPossibleInvitationDateVotesInLocalDBWithDateVotesFromServer(serverPossibleInvitationDateVotes: [PossibleInvitationDateVote], inviteid: String){
        if databaseOpenHandler.open(){
            
            let lockDBDateVotesQueue = dispatch_queue_create("edu.colorado.edu.socialfusion.socialdining.datevote", nil)
            dispatch_sync(lockDBDateVotesQueue) {
                /*Step 1: Delete all local dates votes for the invitation from the localDB*/
                NSLog("\(self.TAG): DB DELETE ALL: Synchronize date votes for invitation")
                let deleteAllPossibleInvitationDateVoteSQL = "DELETE FROM POSSIBLE_INVITATION_DATE_VOTE WHERE inviteid='\(inviteid)'"
                let resultDeleteAllPossibleInvitationDateVote = databaseOpenHandler.socialdiningDB!.executeUpdate(deleteAllPossibleInvitationDateVoteSQL, withArgumentsInArray: nil)
                if !resultDeleteAllPossibleInvitationDateVote{
                    NSLog("\(self.TAG): DB DELETE ALL: Synchronize date votes for invitation: Error: \(databaseOpenHandler.socialdiningDB!.lastErrorMessage())")
                }else{
                    NSLog("\(self.TAG): DB DELETE ALL: Successfully deleted all local date votes for the invitation")
                }
            }
            dispatch_sync(lockDBDateVotesQueue) {
                /*Step 2: Add all server possible invitation date votes to local DB*/
                for serverPossibleInvitationDateVote in serverPossibleInvitationDateVotes{
                    NSLog("\(self.TAG): DB INSERT: Synchronize date votes for invitation")
                    let insertPossibleInvitationDateVoteSQL = "INSERT INTO POSSIBLE_INVITATION_DATE_VOTE (id, inviteid, possible_invitation_date_id, userid, facebookname) VALUES ('\(serverPossibleInvitationDateVote.id!)', '\(inviteid)', '\(serverPossibleInvitationDateVote.possibleInvitationDate!.id!)', '\(serverPossibleInvitationDateVote.userId!)', '\(serverPossibleInvitationDateVote.userName)')"
                    let resultAddPossibleInvitationDateVote = databaseOpenHandler.socialdiningDB!.executeUpdate(insertPossibleInvitationDateVoteSQL, withArgumentsInArray: nil)
                    if !resultAddPossibleInvitationDateVote {
                        NSLog("\(self.TAG): DB INSERT: Synchronize date votes for invitation: Error: \(databaseOpenHandler.socialdiningDB!.lastErrorMessage())")
                    } else {
                        NSLog("\(self.TAG): DB INSERT: Synchronize date votes for invitation: PossibleInvitationDateVote: \(serverPossibleInvitationDateVote.id) Invitation: \(inviteid) was successfuly added to database")
                    }
                }
                
                dispatch_sync(dispatch_get_main_queue(), { () -> Void in
                    NSNotificationCenter.defaultCenter().postNotificationName("redrawInvitationDetailsScreen", object: nil)
                })
            }
        }
    }
    
    func convertJsonToArrayOfPossibleInvitationDateVotes(serverPossibleInvitationDateVotesDataString: NSString)->[PossibleInvitationDateVote]{
        var serverPossibleInvitationDateVotes = [PossibleInvitationDateVote]()
        let serverPossibleInvitationDateVotesData = serverPossibleInvitationDateVotesDataString.dataUsingEncoding(NSUTF8StringEncoding)
        let json = JSON(data: serverPossibleInvitationDateVotesData!)
        if let jsonArray = json.array{
            NSLog("it is an array")
            for possibleInvitationDateVoteJson in jsonArray{
                let possibleInvitationDateVote = Mapper<PossibleInvitationDateVote>().map(possibleInvitationDateVoteJson.description)
                serverPossibleInvitationDateVotes.append(possibleInvitationDateVote!)
            }
        }
        return serverPossibleInvitationDateVotes
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
