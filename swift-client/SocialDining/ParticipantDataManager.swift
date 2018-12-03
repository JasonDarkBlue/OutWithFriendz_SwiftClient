//
//  ParticipantDataManager.swift
//  SocialDining
//
//  Created by KHALED ALALNEZI on 8/15/15.
//  Copyright (c) 2015 University of Colorado, Boulder. All rights reserved.
//

//Singelton pattern
var participantDataManager: ParticipantDataManager = ParticipantDataManager()

import UIKit

class ParticipantDataManager: NSObject {
    
    let TAG = "ParticipantDataManager"
    
    /*A method that posts a new Participant to an Invitation*/
    func postParticipantToInvitationOnServer(newParticipant: User, invitationID: String){
        NSLog("\(self.TAG): Start: Add participant")
        var friendsArray: [NSMutableDictionary] = [NSMutableDictionary]()
        let friendDic: NSMutableDictionary = NSMutableDictionary()
        friendDic.setObject(newParticipant.id!, forKey: "id")
        friendDic.setObject(newParticipant.name!, forKey: "name")
        friendDic.setObject(newParticipant.userProfileImageUrl!, forKey: "userProfileImageUrl")
        friendsArray.append(friendDic)
        /*Prepare HTTP POST request for sending the new Invitation to the server*/
        NSLog("\(self.TAG): HttpPost: Add participant: add user with id: \(newParticipant.id)")
        let request = NSMutableURLRequest(URL: NSURL(string: Config.SERVER_URL+"/invitations/\(invitationID)/addUsers/jsonArray")!)
        let session = NSURLSession.sharedSession()
        request.HTTPMethod = "POST"
        var err: NSError?
        do {
            request.HTTPBody = try NSJSONSerialization.dataWithJSONObject(friendsArray, options: [])
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
                NSLog("\(self.TAG): HttpPost: Add participant: Successfuly posted Final Place to server...")
            } catch {
                // failure
                NSLog("\(self.TAG): HttpPost: Add participant: \((error as NSError).localizedDescription)")
            }
        })
        task.resume()
    }
   
    /*A method that deletes an existing PossibleInvitationDateVote from an Invitation*/
    func deleteParticipantFromInvitationOnServer(userId: NSString, invitationID: String){
        NSLog("\(self.TAG): Start: Delete participant")
        let deleteParticipantURL = Config.SERVER_URL+"/invitations/\(invitationID)/deleteUser/\(userId)"
        let request = NSMutableURLRequest(URL: NSURL(string: deleteParticipantURL)!)
        request.HTTPMethod = "DELETE"
        NSLog("\(self.TAG): HttpDelete: Delete participant")
        httpGet(request){
            (data, error) -> Void in
            if error != nil{
                NSLog("\(self.TAG): HttpDelete: Delete participant: Error: \(error)")
                print(error)
            } else{
                 NSLog("\(self.TAG): HttpDelete: Delete participant: Successfully posted delete Participant to server...")
            }
        }
    }
    
    /*A method that gets all Participants for an invitation*/
    func getListOfParticipantsForInvitationFromlocalDB(inviteid: NSString)->[Participant]{
        var participants: [Participant] = [Participant]()
        if databaseOpenHandler.open(){
            let queryParticipantsSQL = "SELECT id, name, userProfileImageUrl FROM PARTICIPANT WHERE inviteid='\(inviteid)'"
            let participantsResults:FMResultSet? = databaseOpenHandler.socialdiningDB!.executeQuery(queryParticipantsSQL, withArgumentsInArray: nil)
            while participantsResults?.next() == true {
                let participant: Participant = Participant()
                participant.id = participantsResults!.stringForColumn("id")
                participant.name = participantsResults!.stringForColumn("name")
                participant.userProfileImageUrl = participantsResults!.stringForColumn("userProfileImageUrl")
                participants.append(participant)
            }
        }
        NSLog("\(self.TAG): Number of participants from local db: \(participants.count)")
        return participants
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
