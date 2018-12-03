import UIKit
import ObjectMapper

var commentsDataManager: CommentsDataManager = CommentsDataManager()

class CommentsDataManager: NSObject {

    let TAG = "CommentsDataManager"
    
    /*A method that posts a new Comment to an Invitation*/
    func addCommentToInvitation(content: String, invitationID: String, hostId: String, hostName: String){
        NSLog("\(self.TAG): Start: post comment to invitation")
        let newCommentParameters:  NSMutableDictionary = NSMutableDictionary()
        /*preparing host for posting*/
        let hostDic: NSMutableDictionary = NSMutableDictionary()
        hostDic.setObject(hostId, forKey: "id")
        hostDic.setObject(hostName, forKey: "name")
        newCommentParameters.setObject(hostDic, forKey: "user")
        
        /*Adding content*/
        newCommentParameters.setObject(content, forKey: "content")
        
        /*Adding Invitation*/
        let invitationDic:NSMutableDictionary = NSMutableDictionary()
        invitationDic.setObject(invitationID, forKey: "id")
        newCommentParameters.setObject(invitationDic, forKey: "invitation")
        
        /*Adding comment creation date*/
        let date = NSDate()
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "EEE MMM dd HH:mm:ss z yyyy"
        let dateString = dateFormatter.stringFromDate(date)
        newCommentParameters.setObject(dateString, forKey: "created")
        
        /*Post the new request to the server*/
        NSLog("\(self.TAG): HttpPost: post comment to invitation")
        let request = NSMutableURLRequest(URL: NSURL(string: Config.SERVER_URL+"/comments")!)
        let session = NSURLSession.sharedSession()
        request.HTTPMethod = "POST"
        var err: NSError?
        do {
            request.HTTPBody = try NSJSONSerialization.dataWithJSONObject(newCommentParameters, options: [])
        } catch let error as NSError {
            err = error
            NSLog("\(self.TAG): HttpPost: post comment to invitation: Error: \(err!.localizedDescription)")
            request.HTTPBody = nil
        }
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let task = session.dataTaskWithRequest(request, completionHandler: {data, response, error -> Void in
            do {
                let _ = try NSJSONSerialization.JSONObjectWithData(data!, options: [])
                NSLog("\(self.TAG): HttpPost: post comment to invitation: Successfuly posted new comment to server...")
            } catch {
                // failure
                NSLog("\(self.TAG): HttpPost: post comment to invitation: \((error as NSError).localizedDescription)")
            }
        })
        task.resume()

    }
    
    func sychronizeInvitationCommentsWithServerById(inviteid: String){
        NSLog("\(self.TAG): Start: sychronize Invitation Comments With Server")
        ChangeIconVisible().checkChangeIconVisible(inviteid)
        let invitationCommentsInfoURL = Config.SERVER_URL+"/invitations/\(inviteid)/comments"
        let request = NSMutableURLRequest(URL: NSURL(string: invitationCommentsInfoURL)!)
        NSLog("\(self.TAG): HttpGet: sychronize Invitation Comments With Server")
        httpGet(request){
            (data, error) -> Void in
            if error != nil{
                NSLog("\(self.TAG): HttpGet: sychronize Invitation Comments With Server: Error: \(error)")
                print(error)
            } else{
                let serverComments = self.convertJsonToArrayOfComments(data)
                self.addNewCommentToLocalDB(serverComments, inviteid: inviteid)
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    NSNotificationCenter.defaultCenter().postNotificationName("redrawCommentsScreen", object: nil)
                })
            }
        }
    }
    
    /**Method to add new Comment from server to local DB in case a new GCM arrives for a new Comment*/
    func addNewCommentToLocalDB(serverComments: [Comment], inviteid: String){

        if databaseOpenHandler.open(){
            var localCommentsIds: [String] = [String]()
            let querySQL = "SELECT id, inviteid, content FROM COMMENT WHERE inviteid='\(inviteid)'"
            let results:FMResultSet? = databaseOpenHandler.socialdiningDB!.executeQuery(querySQL, withArgumentsInArray: nil)
            while results?.next() == true {
                let id = results!.stringForColumn("id")
                localCommentsIds.append(id)
            }
            /*if server Comment is not found locally, add it to local DB*/
            for serverComment in serverComments{
                var foundFlag = false
                for localCommentId in localCommentsIds{
                    if localCommentId == serverComment.id!{
                        foundFlag = true
                        
                    }
                }
                if !foundFlag{
                    NSLog("\(self.TAG): DB INSERT: add comment")
                    let content = serverComment.content!
                    let escapedContent = content.stringByReplacingOccurrencesOfString("'", withString: "''")
                    let insertCommentSQL = "INSERT INTO COMMENT (id, inviteid, content, userid, facebookname) VALUES ('\(serverComment.id!)', '\(inviteid)', '\(escapedContent)', '\(serverComment.userId!)', '\(serverComment.userName!)')"
                    let resultAddComment = databaseOpenHandler.socialdiningDB!.executeUpdate(insertCommentSQL, withArgumentsInArray: nil)
                    if !resultAddComment {
                        NSLog("\(self.TAG): DB INSERT: add comment: Error: \(databaseOpenHandler.socialdiningDB!.lastErrorMessage())")
                    } else {
                        NSLog("\(self.TAG): DB INSERT: add comment: : Comment: \(serverComment.id) Invitation: \(inviteid) was successfuly added to database")
                        notificationHandler.fireNotification("\(serverComment.userName!) says: \(escapedContent)", alertAction: "open")
                    }
                }
            }
        }

    }
    
    
    /*Method to convert received json array of comments into Array of Comment objects*/
    func convertJsonToArrayOfComments(serverCommentsDataString: NSString)->[Comment]{
        var serverComments = [Comment]()
        let serverCommentsData = serverCommentsDataString.dataUsingEncoding(NSUTF8StringEncoding)
        let json = JSON(data: serverCommentsData!)
        if let jsonArray = json.array{
            for commentJson in jsonArray{
               let comment = Mapper<Comment>().map(commentJson.description)
                serverComments.append(comment!)
            }
        }
        return serverComments
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
