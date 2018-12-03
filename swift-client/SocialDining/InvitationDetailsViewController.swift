import UIKit
import CoreData
import MessageUI
import Social
import CoreLocation

class InvitationDetailsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, MFMessageComposeViewControllerDelegate {
    
    let TAG = "InvitationDetailsViewController"
    
    @IBOutlet weak var invitationDetailsTable: UITableView!
    
    /*Data structure for svaing invitations information retireived from local DB*/
    var invitationID = String()
    var invitation = Invitation()
    var possibleInvitationDateVotesArray: [PossibleInvitationDateVote] = [PossibleInvitationDateVote]()
    /*Dictionary holding the vote count for every PossibleInvitation for display in invitation details table*/
    var possibleInvitationDatesVoteCountDictionary: [String: Int] = [String: Int]()
    /*Dictionary holding if the local user voted for the specific PossibleInvitationDate*/
    var possibleInvitationDatesLocalUserVoteStatusDictionary: [String: Bool] = [String: Bool]()
    var placeVotesArray: [PlaceVote] = [PlaceVote]()
    /*Dictionary holding the vote count for every Place for display in invitation details table*/
    var placesVoteCountDictionary: [String: Int] = [String: Int]()
    /*Dictionary holding if the local user voted for the specific Place*/
    var placesLocalUserVoteStatusDictionary: [String: Bool] = [String: Bool]()
    /*Variables holding user information from NSUserDefaults*/
    var userDic: NSObject?
    var hostName: String?
    var hostId: String?
    /*Variable holding the last search query in the AddPlaceInvitationDetailsViewController*/
    var lastPlaceSearchQuery: NSString?
    var lastPlaceSearchResultsArray: [Restaurant]?
    
    var selectedPlace: Restaurant?
    /*Refresh control variable*/
    var refreshControl:UIRefreshControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadInvitationData()
        
        // Do any additional setup after loading the view.
        self.invitationDetailsTable.registerClass(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
        let nibInvitation = UINib(nibName: "InvitationCell", bundle: nil)
        invitationDetailsTable.registerNib(nibInvitation, forCellReuseIdentifier: "invitation_cell")
        
        let nibDate = UINib(nibName: "DateVotingCell", bundle: nil)
        invitationDetailsTable.registerNib(nibDate, forCellReuseIdentifier: "date_voting_cell")
        
        let nibPlace = UINib(nibName: "PlaceVotingCell", bundle: nil)
        invitationDetailsTable.registerNib(nibPlace, forCellReuseIdentifier: "place_voting_cell")
        
        let nibFriend = UINib(nibName: "FriendCell", bundle: nil)
        invitationDetailsTable.registerNib(nibFriend, forCellReuseIdentifier: "friend_cell")
        
        invitationDetailsTable.allowsSelection = false
        
        /*Get authenticated user information from NSUserDefaults*/
        userDic = userDataManager.getAuthenticatedUser()
        hostName = userDic!.valueForKey("name") as? String
        hostId = userDic!.valueForKey("id") as? String
        
        let buttonFacebook: UIButton = UIButton(type: UIButtonType.Custom)
        buttonFacebook.frame = CGRectMake(0, 0, 23, 23)
        let facebookImage = UIImage(named:"facebook-icon")
        buttonFacebook.setImage(facebookImage, forState: UIControlState.Normal)
        buttonFacebook.addTarget(self, action: "shareToiMessage", forControlEvents: UIControlEvents.TouchUpInside)
        let facebookButtonItem:UIBarButtonItem = UIBarButtonItem(customView: buttonFacebook)
        
        /*Only Add finalize buttons to navigation bar if the user is host*/
        if hostId==invitation.host?.id!{
            /*Adding finalize date button*/
            let buttonFinalizeDate: UIButton = UIButton(type: UIButtonType.Custom)
            buttonFinalizeDate.frame = CGRectMake(0, 0, 23, 23)
            let finalizeDateImage = UIImage(named:"finalize-date-icon")
            buttonFinalizeDate.setImage(finalizeDateImage, forState: UIControlState.Normal)
            buttonFinalizeDate.addTarget(self, action: "finalizeDate", forControlEvents: UIControlEvents.TouchUpInside)
            let finalizeDateBarButtonItem:UIBarButtonItem = UIBarButtonItem(customView: buttonFinalizeDate)
            /*Adding finalize place button*/
            let buttonFinalizePlace: UIButton = UIButton(type: UIButtonType.Custom)
            buttonFinalizePlace.frame = CGRectMake(0, 0, 25, 23)
            let finalizePlaceImage = UIImage(named:"finalize-place-icon")
            buttonFinalizePlace.setImage(finalizePlaceImage, forState: UIControlState.Normal)
            buttonFinalizePlace.addTarget(self, action: "finalizePlace", forControlEvents: UIControlEvents.TouchUpInside)
            let finalizePlaceBarButtonItem:UIBarButtonItem = UIBarButtonItem(customView: buttonFinalizePlace)
            
            self.tabBarController?.navigationItem.setRightBarButtonItems([finalizeDateBarButtonItem,finalizePlaceBarButtonItem, facebookButtonItem], animated: true)
        }else{
            self.tabBarController?.navigationItem.setRightBarButtonItem(facebookButtonItem, animated: true)
        }
        
        /*Setting up refresh control behavior*/
        self.refreshControl = UIRefreshControl()
        self.refreshControl.attributedTitle = NSAttributedString(string: "Fetching invitation data from server...")
        self.refreshControl.addTarget(self, action: Selector("refreshInivtatoinDataFromServer"), forControlEvents: UIControlEvents.ValueChanged)
        self.invitationDetailsTable.addSubview(self.refreshControl)
        
        /*Register new data observer which refreshes the UI*/
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "redrawUI", name: "redrawInvitationDetailsScreen", object: nil)
        
        /*Register connection change observer which display no connection bar and disable some of the functionality*/
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "ReachabilityStatusChanged", name: "ReachStatusChanged", object: nil)
        
        


    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
    override func viewWillAppear(animated: Bool) {
        //code to retrieve invitation from local database
        loadInvitationData()
        refreshInivtatoinDataFromServer()
        let userDic = userDataManager.getAuthenticatedUser() as! NSDictionary
        let id = userDic.valueForKey("id") as! String
        userDataManager.updateUserFriendsOnServer(id)
        userDataManager.synchronizeFriendsPeriodically(true)
    }
    
    //this function returns the number of rows in the table. This number decides how
    //many time the below tableView function will be executed in order to render every
    //cell.
    func numberOfSectionsInTableView(tableView:UITableView) -> Int{
        return 4
    }
    
    
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String?{
        var sectionName = String()
        
        switch (section){
            case 0:
                sectionName = "Invitation Title:"
            case 1:
                sectionName = "Time Voting:"
                break
            case 2:
                sectionName = "Place Voting:"
                break
            case 3:
                sectionName = "Participants:"
                break
            default:
                sectionName = ""
                break
        }
        return sectionName
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let label:UILabel = UILabel()
        switch (section){
        case 0:
            label.text = "    Invitation Title:"
        case 1:
            label.text = "    Time Voting:"
        case 2:
            label.text = "    Place Voting:"
        case 3:
            label.text = "    Participants:"
        default:
            label.text = ""
            break
        }
        label.textColor = UIColor(hue: 0.6917, saturation: 1, brightness: 0.75, alpha: 1.0)
        return label
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        var numberOfRows: Int!
        
        switch (section){
        case 0:
            numberOfRows = 1
            break
        case 1:
            numberOfRows = invitation.possibleInvitationDates!.count+1
            NSLog("\(self.TAG): Displaying : No. of possibleInvitationDates: \(numberOfRows)")
            break
        case 2:
            numberOfRows = invitation.possiblePlaces!.count+1
            NSLog("\(self.TAG): Displaying : No. of possiblePlaces: \(numberOfRows)")
            break
        case 3:
            numberOfRows = invitation.participants!.count+1
            NSLog("\(self.TAG): Displaying : No. of participants: \(numberOfRows)")
            break
        default:
            break
        }
        
        return numberOfRows
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        let section = indexPath.section
        let row = indexPath.row
        
        
        switch editingStyle {
        case .Delete:
            if reachabilityStatus == kREACHABLEWITHWIFI || reachabilityStatus == kREACHABLEWITHWWAN{
                if(section==1){
                    let possibleInvitationDate = invitation.possibleInvitationDates![row]
                    let dateFormatter = NSDateFormatter()
                    dateFormatter.dateFormat = "E, yyyy-MM-dd HH:mm"
                    let dateString = dateFormatter.stringFromDate(possibleInvitationDate.eventDate!)
                    popupMessageHandler.displayMessage("Confirm Deleting Date", content: "Are you sure you want to delete the date \(dateString) from this invitation?", viewController: self){
                        if reachabilityStatus == kREACHABLEWITHWIFI || reachabilityStatus == kREACHABLEWITHWWAN{
                            possibleInvitationDateDataManager.deletePossibleInvitationDateFromInvitationOnServer(possibleInvitationDate, invitationID: self.invitationID)
                        }else{
                            popupMessageHandler.displayInfoMessage("Cannot delete date from invitation.", content: "No Internet connection available.", viewController: self)
                        }
                    }
                }
                if(section==2){
                    let possiblePlace = invitation.possiblePlaces![row]
                    popupMessageHandler.displayMessage("Confirm Deleting Place", content: "Are you sure you want to delete \(possiblePlace.name!) from this invitation?", viewController: self){
                        restaurantDataManager.deletePlaceFromInvitationOnServer(possiblePlace, invitationID: self.invitationID)
                    }
                }
                if(section==3){
                    let participant = invitation.participants![row]
                    let invitationHostId = invitation.host?.id
                    if hostId == participant.id!{
                        popupMessageHandler.displayMessage("Unable to delete.", content: "You are trying to delete yourself. If you would like to leave this invitation you can simply delete it from the invitation list screen.", viewController: self){
                        }
                    }else{
                        if invitationHostId == participant.id!{
                            popupMessageHandler.displayMessage("Unable to delete.", content: "You are trying to delete the host. A host organizes the event and cannot be deleted.", viewController: self){
                            }
                            
                        }else{
                            popupMessageHandler.displayMessage("Confirm Deleting User", content: "Are you sure you want to delete \(participant.name!) from this invitation?", viewController: self){
                                if reachabilityStatus == kREACHABLEWITHWIFI || reachabilityStatus == kREACHABLEWITHWWAN{
                                    participantDataManager.deleteParticipantFromInvitationOnServer(participant.id!, invitationID: self.invitationID)
                                }else{
                                    popupMessageHandler.displayInfoMessage("Cannot delete participant from invitation.", content: "No Internet connection available.", viewController: self)
                                }
                            }
                            
                        }
                    }
                }
            }else{
                popupMessageHandler.displayInfoMessage("Cannot Perform Delete", content: "No Internet connection available.", viewController: self)
            }
            break
        default:
            break
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) ->
        UITableViewCell{
            let section = indexPath.section
            var cell :UITableViewCell!
            switch (section){
            case 0:
                cell = self.invitationDetailsTable.dequeueReusableCellWithIdentifier("cell")!
                if let invitName = invitation.invitationName{
                    cell.textLabel?.text = invitName
                    
                }
                
            case 1:
                cell = self.invitationDetailsTable.dequeueReusableCellWithIdentifier("date_voting_cell") as! DateVotingTableViewCell
                if(indexPath.row==invitation.possibleInvitationDates!.count){
                    (cell as! DateVotingTableViewCell).checkBoxButtonDate.hidden = true
                    (cell as! DateVotingTableViewCell).labelDate.text = ""
                    (cell as! DateVotingTableViewCell).labelFinal.hidden = true
                    (cell as! DateVotingTableViewCell).labelDateCount.hidden = true
                    let addButtonDate: UIButton = UIButton(type: UIButtonType.ContactAdd)
                    addButtonDate.addTarget(self, action: "addNewDate:", forControlEvents: .TouchUpInside)
                    cell.accessoryView = addButtonDate
                }else{
                    let possibleInvitationDate = invitation.possibleInvitationDates![indexPath.row]
                    if let newDate = possibleInvitationDate.eventDate{
                        let dateFormatter = NSDateFormatter()
                        dateFormatter.dateFormat = "E, MM-dd-yyyy HH:mm"
                        let dateString = dateFormatter.stringFromDate(newDate)
                        cell.accessoryView?.hidden = true
                        (cell as! DateVotingTableViewCell).labelDate.text = dateString
                        (cell as! DateVotingTableViewCell).checkBoxButtonDate.tag = indexPath.row
                        (cell as! DateVotingTableViewCell).checkBoxButtonDate.hidden = false
                        (cell as! DateVotingTableViewCell).labelDateCount.hidden = false
                        NSLog("\(self.TAG): Displaying :No. of date counts for date: \(dateString): \(possibleInvitationDatesVoteCountDictionary[possibleInvitationDate.id! as String]!)")
                        (cell as! DateVotingTableViewCell).labelDateCount.text = "\(possibleInvitationDatesVoteCountDictionary[possibleInvitationDate.id! as String]!)"
                        
                        let localUserVotedForThisDate = possibleInvitationDatesLocalUserVoteStatusDictionary[possibleInvitationDate.id! as String]!
                        (cell as! DateVotingTableViewCell).checkBoxButtonDate.removeTarget(nil, action: nil, forControlEvents: .AllEvents)
                        if localUserVotedForThisDate{
                            (cell as! DateVotingTableViewCell).checkVotingBox()
                            (cell as! DateVotingTableViewCell).checkBoxButtonDate.addTarget(self, action: "unVoteForDate:", forControlEvents: UIControlEvents.TouchUpInside)
                        }else{
                            (cell as! DateVotingTableViewCell).unCheckVotingBox()
                            (cell as! DateVotingTableViewCell).checkBoxButtonDate.addTarget(self, action: "voteForDate:", forControlEvents: UIControlEvents.TouchUpInside)
                        }
                        /*Check if this is set to final date and Update UI accordingely*/
                        if let eventDate = invitation.eventDate{
                            print("eventDate: \(eventDate)")
                            (cell as! DateVotingTableViewCell).checkBoxButtonDate.hidden = true
                            if newDate == eventDate{
                                (cell as! DateVotingTableViewCell).labelDate.textColor = UIColorFromRGB(0x008000)
                                (cell as! DateVotingTableViewCell).labelFinal.hidden = false
                            }else{
                                (cell as! DateVotingTableViewCell).labelDate.textColor = UIColor.blackColor()
                                (cell as! DateVotingTableViewCell).labelFinal.hidden = true
                            }
                        }else{
                            (cell as! DateVotingTableViewCell).labelFinal.hidden = true
                            (cell as! DateVotingTableViewCell).checkBoxButtonDate.hidden = false
                        }
                    }
                }
                break
            
            case 2:
                cell = self.invitationDetailsTable.dequeueReusableCellWithIdentifier("place_voting_cell") as! PlaceVotingTableViewCell
                if(indexPath.row==invitation.possiblePlaces!.count){
                    (cell as! PlaceVotingTableViewCell).checkBoxButtonPlace.hidden = true
                    (cell as! PlaceVotingTableViewCell).labelPlaceName.text = ""
                    (cell as! PlaceVotingTableViewCell).labelFinal.hidden = true
                    (cell as! PlaceVotingTableViewCell).labelPlaceCount.hidden = true
                    let addButtonPlace: UIButton = UIButton(type: UIButtonType.ContactAdd)
                    addButtonPlace.addTarget(self, action: "addNewPlace:", forControlEvents: .TouchUpInside)
                    cell.accessoryView = addButtonPlace
                }else{
                    let place = invitation.possiblePlaces![indexPath.row]
                    cell.accessoryView?.hidden = true
                    (cell as! PlaceVotingTableViewCell).labelPlaceName.text = place.name

                    (cell as! PlaceVotingTableViewCell).labelPlaceName.accessibilityValue = place.formattedAddress
                    (cell as! PlaceVotingTableViewCell).labelPlaceName.accessibilityLabel = place.desc
                    (cell as! PlaceVotingTableViewCell).labelPlaceName.textColor = UIColor(hue: 0.6028, saturation: 0.72, brightness: 0.73, alpha: 1.0)
                    (cell as! PlaceVotingTableViewCell).labelPlaceName.accessibilityElements = [place]
                    (cell as! PlaceVotingTableViewCell).labelPlaceName.accessibilityHint = place.userId
                    (cell as! PlaceVotingTableViewCell).labelPlaceName.userInteractionEnabled = true
                    let tap = UITapGestureRecognizer(target: self, action: Selector("LabelLocationTap:"))
                    (cell as! PlaceVotingTableViewCell).labelPlaceName.addGestureRecognizer(tap)
                    

                    
                    
                                        (cell as! PlaceVotingTableViewCell).checkBoxButtonPlace.tag = indexPath.row
                    (cell as! PlaceVotingTableViewCell).checkBoxButtonPlace.hidden = false
                    (cell as! PlaceVotingTableViewCell).labelPlaceCount.hidden = false
                    NSLog("\(self.TAG): Displaying :No. of place counts for place \(place.name!): \(placesVoteCountDictionary[place.id! as String]!)")
                    (cell as! PlaceVotingTableViewCell).labelPlaceCount.text = "\(placesVoteCountDictionary[place.id! as String]!)"
                    let localUserVotedForThisPlace = placesLocalUserVoteStatusDictionary[place.id! as String]!
                    (cell as! PlaceVotingTableViewCell).checkBoxButtonPlace.removeTarget(nil, action: nil, forControlEvents: .AllEvents)
                    if localUserVotedForThisPlace{
                        (cell as! PlaceVotingTableViewCell).checkVotingBox()
                        (cell as! PlaceVotingTableViewCell).checkBoxButtonPlace.addTarget(self, action: "unVoteForPlace:", forControlEvents: UIControlEvents.TouchUpInside)
                    }else{
                        (cell as! PlaceVotingTableViewCell).unCheckVotingBox()
                        (cell as! PlaceVotingTableViewCell).checkBoxButtonPlace.addTarget(self, action: "voteForPlace:", forControlEvents: UIControlEvents.TouchUpInside)
                    }
                    /*Check if this is set to final place and Update UI accordingely*/
                    if let eventPlace = invitation.eventPlace{
                        (cell as! PlaceVotingTableViewCell).checkBoxButtonPlace.hidden = true
                        if place.id == eventPlace.id{
                            (cell as! PlaceVotingTableViewCell).labelPlaceName.textColor = UIColorFromRGB(0x008000)
                            (cell as! PlaceVotingTableViewCell).labelFinal.hidden = false
                        }else{
                            (cell as! PlaceVotingTableViewCell).labelPlaceName.textColor = UIColor(hue: 0.6028, saturation: 0.72, brightness: 0.73, alpha: 1.0)

                            (cell as! PlaceVotingTableViewCell).labelFinal.hidden = true
                        }
                    }else{
                        (cell as! PlaceVotingTableViewCell).labelFinal.hidden = true
                        (cell as! PlaceVotingTableViewCell).checkBoxButtonPlace.hidden = false
                    }
                }
                break
            
            case 3:
                cell = self.invitationDetailsTable.dequeueReusableCellWithIdentifier("friend_cell") as! FriendTableViewCell
                if(indexPath.row==invitation.participants!.count){
                    (cell as! FriendTableViewCell).friendName.text = ""
                    (cell as! FriendTableViewCell).friendImage.hidden = true
                    (cell as! FriendTableViewCell).adminLabel.hidden = true
                    let addButtonFriend: UIButton = UIButton(type: UIButtonType.ContactAdd)
                    addButtonFriend.addTarget(self, action: "addNewFriend:", forControlEvents: .TouchUpInside)
                    cell.accessoryView = addButtonFriend
                }else{
                    let participant = invitation.participants![indexPath.row]
                    cell.accessoryView?.hidden = true
                    (cell as! FriendTableViewCell).friendName.text = participant.name
                    (cell as! FriendTableViewCell).friendImage.hidden = false
                    (cell as! FriendTableViewCell).adminLabel.hidden = true
                    /*Only display images if Internet connection is available*/
                    if reachabilityStatus == kREACHABLEWITHWIFI || reachabilityStatus == kREACHABLEWITHWWAN{
                        if let urlString = participant.userProfileImageUrl{
                            let url = NSURL(string: urlString)
                            let urlRequest = NSURLRequest(URL: url!)
                            NSURLConnection.sendAsynchronousRequest(urlRequest, queue: NSOperationQueue.mainQueue()){ (response:NSURLResponse?, data:NSData?, error:NSError?) -> Void in
                                // Display the image
                                if data != nil{
                                    let image = UIImage(data: data!)
                                    (cell as! FriendTableViewCell).friendImage.image = image
                                }
                            }
                        }
                    }
                    /*Check if current participant is host to enable admin label*/
                    if participant.id! == invitation.host?.id!{
                        (cell as! FriendTableViewCell).adminLabel.hidden = false
                    }
                }
                (cell as! FriendTableViewCell).groupSize.hidden = true
                break
            default:
                break
            }
            return cell
    }
    
    func LabelLocationTap(sender:UIGestureRecognizer){
        let place = (sender.view as? UILabel)?.accessibilityElements![0] as! Restaurant
        if place.userId! == hostId!{
            selectedPlace = place
            self.performSegueWithIdentifier("EditTitleSegue", sender: self)
            
            
        }else{
        if sender.state == .Ended{
            if let theLabel = (sender.view as? UILabel)?.text{
            let address = (sender.view as? UILabel)?.accessibilityValue
            //let desc = (sender.view as? UILabel)?.accessibilityLabel
            popupMessageHandler.displayInfoMessage(theLabel, content: address!, viewController: self)
            }
            
        }
    }
        
        
        
    }
    
    func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        if(indexPath.section==0){
            return UITableViewCellEditingStyle.None
        }
        /*Disbale delete cell for all PossibleInvitationDates in case final PossibleInvitationDate is set*/
        /*or only for the last cell if final PossibleInvitationDate is not set*/
        if(indexPath.section==1){
            if let _ = invitation.eventDate{
                return UITableViewCellEditingStyle.None
            }else if(indexPath.row==invitation.possibleInvitationDates!.count){
                return UITableViewCellEditingStyle.None
            }
        }
        
        /*Disbale delete cell for all Places in case final Place is set*/
        /*or only for the last cell if final Place is not set*/
        if(indexPath.section==2){
            if let _ = invitation.eventPlace{
                return UITableViewCellEditingStyle.None
            }else if(indexPath.row==invitation.possiblePlaces!.count){
                return UITableViewCellEditingStyle.None
            }
        }
        
        if(indexPath.section==2 && indexPath.row==invitation.participants!.count){
            return UITableViewCellEditingStyle.None
        }
        return UITableViewCellEditingStyle.Delete
    }
    
    /*Message compose delegate method*/
    func messageComposeViewController(controller: MFMessageComposeViewController, didFinishWithResult result: MessageComposeResult) {
        switch (result.rawValue) {
        case MessageComposeResultCancelled.rawValue:
            self.dismissViewControllerAnimated(true, completion: nil)
            let alertCancel = UIAlertController(title: "Warning", message: "Message Cancalled.", preferredStyle: UIAlertControllerStyle.Alert)
            alertCancel.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
            self.presentViewController(alertCancel, animated: true, completion: nil)
            break
        case MessageComposeResultFailed.rawValue:
            self.dismissViewControllerAnimated(true, completion: nil)
            let alertFailed = UIAlertController(title: "Warning", message: "Message Failed.", preferredStyle: UIAlertControllerStyle.Alert)
            alertFailed.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
            self.presentViewController(alertFailed, animated: true, completion: nil)
            break
        case MessageComposeResultSent.rawValue:
            self.dismissViewControllerAnimated(true, completion: nil)
            let alertSent = UIAlertController(title: "Warning", message: "Message Sent.", preferredStyle: UIAlertControllerStyle.Alert)
            alertSent.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
            self.presentViewController(alertSent, animated: true, completion: nil)
            break
        default:
            break;
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if(segue.identifier == "EditTitleSegue"){
            let nav = segue.destinationViewController as! UINavigationController
            let editTitleViewController = nav.topViewController as! EditTitleViewController
                editTitleViewController.placeInvitation = selectedPlace
                editTitleViewController.invitation = invitation
        }


        if(segue.identifier == "addPlaceInvitationDetailsSegue"){
            if (lastPlaceSearchQuery != nil){
                let nav = segue.destinationViewController as! UINavigationController
                let addPlaceInvitationDetailsViewController = nav.topViewController as! AddPlaceInvitationDetailsViewController
                addPlaceInvitationDetailsViewController.lastPlaceSearchQuery = lastPlaceSearchQuery!
                if (!(lastPlaceSearchResultsArray?.isEmpty)!){
                    addPlaceInvitationDetailsViewController.lastPlaceSearchResultsArray = lastPlaceSearchResultsArray!
                }
            }
        }
        
        if(segue.identifier == "addFriendInvitationDetailsSegue"){
            let nav = segue.destinationViewController as! UINavigationController
            let addFriendInvitationDetailsViewController = nav.topViewController as! AddFriendInvitationDetailsViewController
            addFriendInvitationDetailsViewController.inviteid = invitationID
            
        }
        /*
        if(segue.identifier == "editDescription"){
            let nav = segue.destinationViewController as! UINavigationController
            let _ = nav.topViewController as! EditDescriptionViewController
            
            
        }*/
    }
    
    /*Unwind AddDateInvitationDetailsViewController methods*/
    @IBAction func cancelToAddDateInvitationDetailsViewController(segue:UIStoryboardSegue) {
        /*Nothing happens*/
    }
    
    @IBAction func saveDateInvitationDetailsViewScreen(segue:UIStoryboardSegue) {
        /*Post date to invitation & refresh UI*/
        let addDateInvitationDetailsViewController = segue.sourceViewController as! AddDateInvitationDetailsViewController
        let newPossibleInvitationDate = addDateInvitationDetailsViewController.newPossibleInvitationDate
        if reachabilityStatus == kREACHABLEWITHWIFI || reachabilityStatus == kREACHABLEWITHWWAN{
            possibleInvitationDateDataManager.postPossibleInvitationDateToInvitationOnServer(newPossibleInvitationDate, invitationID: invitationID)
        }else{
            popupMessageHandler.displayInfoMessage("Cannot post date to invitation.", content: "No Internet connection available.", viewController: self)
        }
    }
    
    /*Unwind AddPlaceInvitationDetailsViewController methods*/
    @IBAction func cancelToAddPlaceInvitationDetailsViewController(segue:UIStoryboardSegue) {
        /*Clear last cached search*/
        lastPlaceSearchQuery = nil
        lastPlaceSearchResultsArray = nil
    }
    
    @IBAction func savePlacenvitationDetailsViewScreen(segue:UIStoryboardSegue) {
        /*Post date to invitation & refresh UI*/
        let addPlaceInvitationDetailsViewController = segue.sourceViewController as! AddPlaceInvitationDetailsViewController
        let newPlace = addPlaceInvitationDetailsViewController.newRest
        lastPlaceSearchQuery = addPlaceInvitationDetailsViewController.searchTextField.text
        lastPlaceSearchResultsArray = addPlaceInvitationDetailsViewController.lastPlaceSearchResultsArray
        restaurantDataManager.postPlaceToInvitationOnServer(newPlace, invitationID: invitationID)
        
    }
    
    /*Unwind AddFriendInvitationDetailsViewController methods*/
    @IBAction func cancelToAddFriendInvitationDetailsViewController(segue:UIStoryboardSegue) {
        /*Nothing happens*/
    }

    @IBAction func saveFriendInvitationDetailsViewScreen(segue: UIStoryboardSegue){
        let addFriendInvitationDetailsViewController = segue.sourceViewController as! AddFriendInvitationDetailsViewController
        let newFriend = addFriendInvitationDetailsViewController.selectedFriend
        if reachabilityStatus == kREACHABLEWITHWIFI || reachabilityStatus == kREACHABLEWITHWWAN{
            participantDataManager.postParticipantToInvitationOnServer(newFriend!, invitationID: invitationID)
        }else{
            popupMessageHandler.displayInfoMessage("Cannot post participant to invitation.", content: "No Internet connection available.", viewController: self)
        }
        
    }
    
    func loadInvitationData(){
        invitation = invitationDataManager.getInvitation(invitationID)
        invitation.changeIconVisible = false
        
        let updateChangeIconVisibleSQL = "UPDATE INVITATION SET changeIconVisible = 0 WHERE id='\(invitationID)'"
        let resultChangeIcon = databaseOpenHandler.socialdiningDB!.executeUpdate(updateChangeIconVisibleSQL, withArgumentsInArray: nil)
        if !resultChangeIcon {
            NSLog("\(self.TAG): DB UPDATE: ChangeIconVisible: Error: \(databaseOpenHandler.socialdiningDB!.lastErrorMessage())")
        } else {
            NSLog("\(self.TAG): DB UPDATE: ChangeIconVisible: for Invitation: \(invitation.invitationName) was successfuly added to the database.")
        }
        /*Possible invitation date voting logic*/
        possibleInvitationDateVotesArray = possibleInvitationDateVoteDataManager.getListOfPossibleInvitationDateVotesForInvitationFromLocalDB(invitationID)
        /*Count number of votes for every date and store in Dictionary <Stirng, Int>*/
        for possibleInvitationDate in invitation.possibleInvitationDates!{
            var counter = 0
            for possibleInvitationDateVote in possibleInvitationDateVotesArray{
                if possibleInvitationDate.id! == possibleInvitationDateVote.possibleInvitationDate!.id!{
                    counter++
                }
            }
            possibleInvitationDatesVoteCountDictionary[possibleInvitationDate.id! as String] = counter
        }
        /*Check of local user voted for for every date and store in Dictionary <Stirng, Bool>*/
        for possibleInvitationDate in invitation.possibleInvitationDates!{
            var voted = false
            for possibleInvitationDateVote in possibleInvitationDateVotesArray{
                if possibleInvitationDate.id! == possibleInvitationDateVote.possibleInvitationDate!.id!{
                    if possibleInvitationDateVote.userId! == hostId{
                        voted = true
                    }
                }
            }
            possibleInvitationDatesLocalUserVoteStatusDictionary[possibleInvitationDate.id! as String] = voted
        }
        /*Possible places voting logic*/
        placeVotesArray = placeVoteDataManager.getListOfPlaceVotesForInvitationFromLocalDB(invitationID)
        /*Count number of votes for every date and store in Dictionary <Stirng, Int>*/
        for place in invitation.possiblePlaces!{
            var counter = 0
            for placeVote in placeVotesArray{
                if place.id! == placeVote.place!.id!{
                    counter++
                }
            }
            placesVoteCountDictionary[place.id! as String] = counter
        }
        
        /*Check of local user voted for for every date and store in Dictionary <Stirng, Bool>*/
        for place in invitation.possiblePlaces!{
            var voted = false
            for placeVote in placeVotesArray{
                if place.id! == placeVote.place!.id!{
                    if placeVote.userId! == hostId{
                        voted = true
                    }
                }
            }
            placesLocalUserVoteStatusDictionary[place.id! as String] = voted
        }
    }
    
    /*Method to handle screen refresh request & Manual connect everytime the screen is launched*/
    func refreshInivtatoinDataFromServer(){
        /*Only perform manual synchronization when there is Internet connectivity*/
        if reachabilityStatus == kREACHABLEWITHWIFI || reachabilityStatus == kREACHABLEWITHWWAN{
            /*
            invitationDataManager.sychronizeInvitationWithServerById(invitationID)
            possibleInvitationDateVoteDataManager.copyInvitationDateVotesFromServerById(invitationID)
            placeVoteDataManager.copyInvitationPlaceVotesFromServerById(invitationID)*/
            //refreshInivtatoinDataFromServer()
            redrawUI()
        }else{
            popupMessageHandler.displayInfoMessage("Cannot Refresh This Invitation", content: "No Internet connection available.", viewController: self)
        }
        
        

        self.refreshControl.endRefreshing()
    }
    
    /*Method to refresh the UI from local DB*/
    func redrawUI(){
        NSLog("\(self.TAG): redrawUI")
        loadInvitationData()
        invitationDetailsTable.reloadData()
    }
    
    func voteForPlace(sender: UIButton!) {
        NSLog("\(self.TAG): voteForPlace")
        if reachabilityStatus == kREACHABLEWITHWIFI || reachabilityStatus == kREACHABLEWITHWWAN{
            let newPlaceVote: PlaceVote = PlaceVote()
            newPlaceVote.place = invitation.possiblePlaces![sender.tag]
            let placeCell: PlaceVotingTableViewCell = (sender.superview?.superview as? PlaceVotingTableViewCell)!
            placeCell.toggleHeart()
            placeVoteDataManager.postPlaceVoteToInvitationOnServer(newPlaceVote, invitationID: invitationID, hostId: hostId!, hostName: hostName!)
        }else{
            popupMessageHandler.displayInfoMessage("Cannot Perform Voting", content: "No Internet connection available.", viewController: self)
        }
    }
    
    func voteForDate(sender: UIButton!){
        NSLog("\(self.TAG): voteForDate")
        
        if reachabilityStatus == kREACHABLEWITHWIFI || reachabilityStatus == kREACHABLEWITHWWAN{
            let newPossibleInvitationDateVote: PossibleInvitationDateVote = PossibleInvitationDateVote()
            newPossibleInvitationDateVote.possibleInvitationDate = invitation.possibleInvitationDates![sender.tag]
            let dateCell: DateVotingTableViewCell = (sender.superview?.superview as? DateVotingTableViewCell)!
            dateCell.toggleHeart()
            possibleInvitationDateVoteDataManager.postPossibleInvitationDateVoteToInvitationOnServer(newPossibleInvitationDateVote, invitationID: invitationID, hostId: hostId!, hostName: hostName!)
        }else{
            popupMessageHandler.displayInfoMessage("Cannot Perform Voting", content: "No Internet connection available.", viewController: self)
        }
    }
    
    func unVoteForPlace(sender: UIButton!){
        NSLog("\(self.TAG): unVoteForPlace")
        if reachabilityStatus == kREACHABLEWITHWIFI || reachabilityStatus == kREACHABLEWITHWWAN{
            /*Get the Place object to delete its corresponding local user vote*/
            let place = invitation.possiblePlaces![sender.tag]
            /*Get the corresponding local user PlaceVote for this Place object*/
            for placeVote in placeVotesArray{
                if place.id! == placeVote.place!.id!{
                    if placeVote.userId! == hostId{
                        /*Delete the local user PlaceVote*/
                        let placeCell: PlaceVotingTableViewCell = (sender.superview?.superview as? PlaceVotingTableViewCell)!
                        placeCell.toggleHeart()
                        placeVoteDataManager.deletePlaceVoteFromInvitationFromServer(placeVote, invitationID: invitationID, hostId: hostId!, hostName: hostName!)
                    }
                }
            }
        }else{
            popupMessageHandler.displayInfoMessage("Cannot Perform Voting", content: "No Internet connection available.", viewController: self)
        }
    }
    
    func unVoteForDate(sender: UIButton!){
        NSLog("\(self.TAG): unVoteForDate")
        if reachabilityStatus == kREACHABLEWITHWIFI || reachabilityStatus == kREACHABLEWITHWWAN{
            /*Get the PossibleInvitationDate object to delete its corresponding local user vote*/
            let possibleInvitationDate = invitation.possibleInvitationDates![sender.tag]
            /*Get the corresponding local user PossibleInvitationDateVote for this PossibleInvitationDate object*/
            for possibleInvitationDateVote in possibleInvitationDateVotesArray{
                if possibleInvitationDate.id! == possibleInvitationDateVote.possibleInvitationDate!.id!{
                    if possibleInvitationDateVote.userId! == hostId{
                        /*Delete the local user PossibleInvitationDateVote*/
                        let dateCell: DateVotingTableViewCell = (sender.superview?.superview as? DateVotingTableViewCell)!
                        dateCell.toggleHeart()
                        possibleInvitationDateVoteDataManager.deletePossibleInvitationDateVoteFromInvitationOnServer(possibleInvitationDateVote, invitationID: invitationID, hostId: hostId!, hostName: hostName!)
                    }
                }
            }
        }else{
            popupMessageHandler.displayInfoMessage("Cannot Perform Voting", content: "No Internet connection available.", viewController: self)
        }
    }
    
    /*Finalize invitation date method*/
    func finalizeDate() {
        if reachabilityStatus == kREACHABLEWITHWIFI || reachabilityStatus == kREACHABLEWITHWWAN{
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateFormat = "E, MM-dd-yyyy HH:mm"
            let alert = UIAlertController(title: "Final Date Selection", message: "Please choose a final date for the invitation.", preferredStyle: UIAlertControllerStyle.Alert)
            for possibleInvitationDate in invitation.possibleInvitationDates!{
                let dateString = dateFormatter.stringFromDate(possibleInvitationDate.eventDate!)
                let alertAction = UIAlertAction(title: "\(dateString)", style: UIAlertActionStyle.Default, handler: { (actionSheetController) -> Void in
                    let date = dateFormatter.dateFromString(dateString)
                    let finalPossibleInvitationDate: PossibleInvitationDate = PossibleInvitationDate()
                    finalPossibleInvitationDate.eventDate = date
                    possibleInvitationDateDataManager.postFinalPossibleInvitationDateToInvitationOnServer(possibleInvitationDate, invitationID: self.invitation.id!)
                })
                alert.addAction(alertAction)
            }
            let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Destructive, handler: nil)
            alert.addAction(cancelAction)
            presentViewController(alert, animated: true, completion: nil)
        }else{
            popupMessageHandler.displayInfoMessage("Cannot Finalize Date", content: "No Internet connection available.", viewController: self)
        }
    }
    
    /*Finalize invitation Place method*/
    func finalizePlace() {
        if reachabilityStatus == kREACHABLEWITHWIFI || reachabilityStatus == kREACHABLEWITHWWAN{
            let alert = UIAlertController(title: "Final Place Selection", message: "Please choose a final place for the invitation.", preferredStyle: UIAlertControllerStyle.Alert)
            for possiblePlace in invitation.possiblePlaces!{
                let alertAction = UIAlertAction(title: "\(possiblePlace.name!)", style: UIAlertActionStyle.Default, handler: { (actionSheetController) -> Void in
                    NSLog("Chosen place: \(possiblePlace.name!)")
                    restaurantDataManager.postFinalPlaceToInvitationOnServer(possiblePlace, invitationID: self.invitation.id!)
                })
                alert.addAction(alertAction)
            }
            let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Destructive, handler: nil)
            alert.addAction(cancelAction)
            presentViewController(alert, animated: true, completion: nil)
        }else{
            popupMessageHandler.displayInfoMessage("Cannot Finalize Place", content: "No Internet connection available.", viewController: self)
        }
    }
    
    /*Methods to handle adding new date, place and friend*/
    func addNewDate(sender: UIButton!){
        if reachabilityStatus == kREACHABLEWITHWIFI || reachabilityStatus == kREACHABLEWITHWWAN{
            self.performSegueWithIdentifier("addDateInvitationDetailsSegue", sender: self)
        }else{
            popupMessageHandler.displayInfoMessage("Cannot Add Date", content: "No Internet connection available.", viewController: self)
        }
    }
    
    func addNewPlace(sender: UIButton!){
        if reachabilityStatus == kREACHABLEWITHWIFI || reachabilityStatus == kREACHABLEWITHWWAN{
            if CLLocationManager.locationServicesEnabled() {
                switch(CLLocationManager.authorizationStatus()) {
                    case .NotDetermined, .Restricted, .Denied:
                        popupMessageHandler.displayInfoMessage("Info", content: "Sorry, please go to privacy settings to enable location services for OWF.", viewController: self)
                        break
                    case .AuthorizedAlways, .AuthorizedWhenInUse:
                        self.performSegueWithIdentifier("addPlaceInvitationDetailsSegue", sender: self)
                        break
                }
            }else{
                popupMessageHandler.displayInfoMessage("Info", content: "Sorry, please go to privacy settings to enable location services.", viewController: self)
            }
        }else{
            popupMessageHandler.displayInfoMessage("Cannot Add Place", content: "No Internet connection available.", viewController: self)
        }
    }
    
    func addNewFriend(sender: UIButton!){
        if reachabilityStatus == kREACHABLEWITHWIFI || reachabilityStatus == kREACHABLEWITHWWAN{
            self.performSegueWithIdentifier("addFriendInvitationDetailsSegue", sender: self)
        }else{
            popupMessageHandler.displayInfoMessage("Cannot Add Friends", content: "No Internet connection available.", viewController: self)
        }
    }

    /*A method to share the invitation with friends*/
    func shareToiMessage(){
        
        if(MFMessageComposeViewController.canSendText()){
            let messageVC = MFMessageComposeViewController()
            var msgContent: String = String()
            msgContent = ""
            /*The displayed message to share the invitation depends on whether the invitation meeting*/
            /*time and meeting location are set*/
            
            /*Case 1: final time and final location are not set*/
            if invitation.eventDate == nil && invitation.eventPlace == nil{
                msgContent = "Hello, I would like to share the event: ("+invitation.invitationName!+") with you, please install OutWithFriendz app from the App Store to join me! \nhttps://itunes.apple.com/us/app/outwithfriendz/id1050504914?ls=1&mt=8"
            }
            
            /*Case 2: only final time is set*/
            if invitation.eventDate != nil && invitation.eventPlace == nil{
                let eventDate = invitation.eventDate!
                let dateFormatter = NSDateFormatter()
                dateFormatter.dateFormat = "MMM dd KK:mm aa"
                let eventDateString = dateFormatter.stringFromDate(eventDate)
                msgContent = "Hello, we are meeting for the event: ("+invitation.invitationName!+") at the following date: (\(eventDateString)), please install OutWithFriendz app from the App Store to decide the location with us! \nhttps://itunes.apple.com/us/app/outwithfriendz/id1050504914?ls=1&mt=8"
            }

            /*Case 3: only final place is set*/
            if invitation.eventDate == nil && invitation.eventPlace != nil{
                var placeNameString = ""
                if let placeName = invitation.eventPlace?.name{
                    placeNameString = placeName
                }
                msgContent = "Hello, we are meeting for the event: ("+invitation.invitationName!+") at the following location: (\(placeNameString)), please install OutWithFriendz app from the App Store to decide the time with us! \nhttps://itunes.apple.com/us/app/outwithfriendz/id1050504914?ls=1&mt=8"
            }
            /*Case 4: both final time and final location are set*/
            if invitation.eventDate != nil && invitation.eventPlace != nil{
                var placeNameString = ""
                let eventDate = invitation.eventDate!
                let dateFormatter = NSDateFormatter()
                dateFormatter.dateFormat = "MMM dd KK:mm aa"
                let eventDateString = dateFormatter.stringFromDate(eventDate)
                if let placeName = invitation.eventPlace?.name{
                    placeNameString = placeName
                }
                msgContent = "Hello, we are meeting for the event: ("+invitation.invitationName!+") at the following date:(\(eventDateString)) and the following location:(\(placeNameString)), please install OutWithFriendz app from App Store to join us! \nhttps://itunes.apple.com/us/app/outwithfriendz/id1050504914?ls=1&mt=8"
            }
            
            messageVC.body = msgContent
            messageVC.messageComposeDelegate = self;
            self.presentViewController(messageVC, animated: false, completion: nil)
        }else{
            popupMessageHandler.displayInfoMessage("Error!", content: "Sorry, please check your SMS status.", viewController: self)
        }
    }
    
    func UIColorFromRGB(rgbValue: UInt) -> UIColor {
        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
    
    func ReachabilityStatusChanged(){
        if reachabilityStatus == kNOTREACHABLE{
            NSLog("Deactivate interface...")
        }else if reachabilityStatus == kREACHABLEWITHWIFI || reachabilityStatus == kREACHABLEWITHWWAN{
            NSLog("Activate interface...")
        }
    }
    
    @IBAction func cancelEditPlaceViewController(segue:UIStoryboardSegue) {
    }
    
    @IBAction func saveEditPlace(segue:UIStoryboardSegue) {
        let editTitleViewController = segue.sourceViewController as! EditTitleViewController
        let place = editTitleViewController.placeInvitation!
        place.name = editTitleViewController.titleInvitation.text
        let invitation = editTitleViewController.invitation!
        var index = 0
        for possiblePlace in invitation.possiblePlaces!{
            if possiblePlace.id! == place.id!{
                restaurantDataManager.updatePlaceToInvitationOnServer(place, invitationID: invitation.id!)
            }
            index += 1
        }
        refreshInivtatoinDataFromServer()
        redrawUI()
            
            
        
    }
    
    
    
    deinit{
        NSNotificationCenter.defaultCenter().removeObserver(self, name: "redrawInvitationDetailsScreen", object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: "ReachStatusChanged", object: nil)
    }
}
