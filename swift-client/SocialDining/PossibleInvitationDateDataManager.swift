var possibleInvitationDateDataManager: PossibleInvitationDateDataManager = PossibleInvitationDateDataManager()

import UIKit

class PossibleInvitationDateDataManager: NSObject {
    
    let TAG = "PossibleInvitationDateDataManager"
    
    /*A method that posts a new PossibleInvitationDate to an Invitation*/
    func postPossibleInvitationDateToInvitationOnServer(newPossibleInvitationDate: PossibleInvitationDate, invitationID: String){
        NSLog("\(self.TAG): Start: post date: \(newPossibleInvitationDate.eventDate!) to invite:\(invitationID)")
        /*Convert date for posting*/
        let newPossibleInvitationDateParameters:  NSMutableDictionary = NSMutableDictionary()
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "EEE MMM dd HH:mm:ss z yyyy"
        let dateString = dateFormatter.stringFromDate(newPossibleInvitationDate.eventDate!)
        newPossibleInvitationDateParameters.setObject(dateString, forKey: "eventDate")
        /*First, we need to create the new PossibleInvitationDate object on the server side*/
        let createNewPossibleInvitationDateRequest = NSMutableURLRequest(URL: NSURL(string: Config.SERVER_URL+"/possibleInvitationDates")!)
        let session = NSURLSession.sharedSession()
        createNewPossibleInvitationDateRequest.HTTPMethod = "POST"
        var err: NSError?
        do {
            createNewPossibleInvitationDateRequest.HTTPBody = try NSJSONSerialization.dataWithJSONObject(newPossibleInvitationDateParameters, options: [])
        } catch let error as NSError {
            err = error
            print("\(self.TAG): \(err?.localizedDescription)")
            createNewPossibleInvitationDateRequest.HTTPBody = nil
        }
        createNewPossibleInvitationDateRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        createNewPossibleInvitationDateRequest.addValue("application/json", forHTTPHeaderField: "Accept")
        NSLog("\(self.TAG): HttpPost: post date")
        let createNewPossibleInvitationDateTask = session.dataTaskWithRequest(createNewPossibleInvitationDateRequest, completionHandler: {data, response, error -> Void in
            /*strData containts the body of the response*/
            /*Get new possibleInvitationDate Id frpm returned data*/
            let strData = NSString(data: data!, encoding: NSUTF8StringEncoding)
            let newPossibleInvitationDateId = strData!
            
            /*Use the new returned Id for the new PossibleInvitationDate to post the new Object to the Invitation*/
            newPossibleInvitationDateParameters.setObject(newPossibleInvitationDateId, forKey: "id")
            let postPossibleInvitationDateToInvitationRequest = NSMutableURLRequest(URL: NSURL(string: Config.SERVER_URL+"/invitations/"+invitationID+"/possibleInvitationDates")!)
            postPossibleInvitationDateToInvitationRequest.HTTPMethod = "POST"
            do {
                postPossibleInvitationDateToInvitationRequest.HTTPBody = try NSJSONSerialization.dataWithJSONObject(newPossibleInvitationDateParameters, options: [])
            } catch let error as NSError {
                err = error
                postPossibleInvitationDateToInvitationRequest.HTTPBody = nil
            } catch {
                fatalError()
            }
            postPossibleInvitationDateToInvitationRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
            postPossibleInvitationDateToInvitationRequest.addValue("application/json", forHTTPHeaderField: "Accept")
            
            NSLog("\(self.TAG): HttpPost: New PossibleInvitationDate")
            let postPossibleInvitationDateToInvitationTask = session.dataTaskWithRequest(postPossibleInvitationDateToInvitationRequest, completionHandler: {data, response, error -> Void in
                do {
                    let _ = try NSJSONSerialization.JSONObjectWithData(data!, options: [])
                     NSLog("\(self.TAG): HttpPost: New PossibleInvitationDate: Successfuly posted new possible invitation date to server...")
                } catch {
                    // failure
                    NSLog("\(self.TAG): HttpPost: New PossibleInvitationDate: \((error as NSError).localizedDescription)")
                }
            })
            postPossibleInvitationDateToInvitationTask.resume()
        })
        createNewPossibleInvitationDateTask.resume()
    }
    
    /*A method that deletes an existing PossibleInvitationDate from an Invitation*/
    func deletePossibleInvitationDateFromInvitationOnServer(possibleInvitationDate: PossibleInvitationDate, invitationID: String){
        NSLog("\(self.TAG): Start: Delete possibleInvitationDate: \(possibleInvitationDate.id!) from invite: \(invitationID)")
        //To-do: the delete takes NO PARAMETER
        //It is only a call to "/possibleInvitationDateVotes/{voteid}"
        
        let possibleInvitationDateId = possibleInvitationDate.id!
        let deletePossibleInvitationDateURL = Config.SERVER_URL+"/invitations/\(invitationID)/deletePossibleInvitationDate/\(possibleInvitationDateId)"
        let request = NSMutableURLRequest(URL: NSURL(string: deletePossibleInvitationDateURL)!)
        request.HTTPMethod = "DELETE"
        NSLog("\(self.TAG): HttpPost: Del possibleInvitationDate")
        httpGet(request){
            (data, error) -> Void in
            if error != nil{
                 NSLog("\(self.TAG): HttpPost: Del possibleInvitationDate: \(error)")
            } else{
                NSLog("\(self.TAG): HttpPost: Del possibleInvitationDate: Successfully posted delete PossibleInvitationDate to server...")
            }
        }
        
    }
    
    /*A method that gets all PossibleInvitationDates for an invitation*/
    func getListOfPossibleInvitationDatesForInvitationFromLocalDB(inviteid: NSString)->[PossibleInvitationDate]{
        var possibleInvitationDates: [PossibleInvitationDate] = [PossibleInvitationDate]()
        
        if databaseOpenHandler.open(){
            let queryPossibleInvitationDatesSQL = "SELECT id, inviteid, eventDate FROM POSSIBLE_INVITATION_DATE WHERE inviteid='\(inviteid)'"
            let possibleInvitationDateResults:FMResultSet? = databaseOpenHandler.socialdiningDB!.executeQuery(queryPossibleInvitationDatesSQL, withArgumentsInArray: nil)
            while possibleInvitationDateResults?.next() == true {
                let possibleInvitationDate: PossibleInvitationDate = PossibleInvitationDate()
                possibleInvitationDate.id = possibleInvitationDateResults!.stringForColumn("id")
                /*Convert epoch to NSDate*/
                let eventDateLong = possibleInvitationDateResults!.intForColumn("eventDate")
                let seconds = NSTimeInterval(eventDateLong)
                let eventDate = NSDate(timeIntervalSince1970: seconds)
                possibleInvitationDate.eventDate = eventDate
                possibleInvitationDates.append(possibleInvitationDate)
            }
        }
        return possibleInvitationDates
    }
    
    func postFinalPossibleInvitationDateToInvitationOnServer(finalPossibleInvitationDate: PossibleInvitationDate, invitationID: String){
        NSLog("\(self.TAG): Start: post final place")
        var dateLong: Double = Double()
        dateLong = (finalPossibleInvitationDate.eventDate!.timeIntervalSince1970)*1000
        let dateString:String = String(format:"%.f", dateLong)
        let data = (dateString as NSString).dataUsingEncoding(NSUTF8StringEncoding)
        let postFinalPossibleInvitationDateToInvitationRequest = NSMutableURLRequest(URL: NSURL(string: Config.SERVER_URL+"/invitations/"+invitationID+"/eventDate")!)

        let session = NSURLSession.sharedSession()
        postFinalPossibleInvitationDateToInvitationRequest.HTTPMethod = "PUT"
        postFinalPossibleInvitationDateToInvitationRequest.HTTPBody = data
        postFinalPossibleInvitationDateToInvitationRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        postFinalPossibleInvitationDateToInvitationRequest.addValue("application/json", forHTTPHeaderField: "Accept")
        debugRequest(postFinalPossibleInvitationDateToInvitationRequest)
        NSLog("\(self.TAG): HttpPost: post final place")
        let postFinalPossibleInvitationDateToInvitationTask = session.dataTaskWithRequest(postFinalPossibleInvitationDateToInvitationRequest, completionHandler: {data, response, error -> Void in
            do {
                let _ = try NSJSONSerialization.JSONObjectWithData(data!, options: [])
                NSLog("\(self.TAG): HttpPost: Successfuly posted Final Possible Invitation Date to server...")
            } catch {
                // failure
                NSLog("\(self.TAG): HttpPost: Error: \((error as NSError).localizedDescription)")
            }
        })
        postFinalPossibleInvitationDateToInvitationTask.resume()
    }
    
    func debugRequest(request: NSMutableURLRequest){
        print("Debug information for URL request: ")
        print(request.allHTTPHeaderFields)
        let body = NSString(data: request.HTTPBody!, encoding: NSUTF8StringEncoding)!
        print(body)
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
