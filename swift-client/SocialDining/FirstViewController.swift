import UIKit
import MessageUI


class FirstViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    let TAG = "FirstViewController"

    @IBOutlet var tblInvitations: UITableView!
    @IBOutlet weak var settingsButton: UIBarButtonItem!
    
    var refreshControl:UIRefreshControl!
    
    var invitations: [Invitation] = [Invitation]()
    
    var emptyLabel: UILabel = UILabel(frame: CGRectMake(0, 0, 300, 100))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.hidesBackButton = true
        // Do any additional setup after loading the view, typically from a nib.
        //regiser invitation cell
        let nib = UINib(nibName: "InvitationCell", bundle: nil)
        tblInvitations.registerNib(nib, forCellReuseIdentifier: "invitation_cell")
        tblInvitations.rowHeight = 75
        self.refreshControl = UIRefreshControl()
        self.refreshControl.attributedTitle = NSAttributedString(string: "Fetching invitations list from server...")
        self.refreshControl.addTarget(self, action: Selector("refreshInivtatoinsListFromServer"), forControlEvents: UIControlEvents.ValueChanged)
        self.tblInvitations.addSubview(self.refreshControl)

        /*Register refresh UI function*/
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "redrawUI", name: "redrawInvitationListID", object: nil)
        
        /*Preparing empty lavel for use*/
        emptyLabel.center = CGPointMake(160, 284)
        emptyLabel.textAlignment = NSTextAlignment.Center
        emptyLabel.text = "You don't have any active invitations. Tap + to create a new invitation!"
        emptyLabel.lineBreakMode = .ByWordWrapping
        emptyLabel.numberOfLines = 3
        self.view.addSubview(emptyLabel)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //this is fired when returning to the view
    override func viewWillAppear(animated: Bool) {
        //the reload data will cause the below two functions to be called back again
        redrawUI()
        refreshInivtatoinsListFromServer()
        
        let url = NSURL(string: "https://csel.cs.colorado.edu/~shzh3550/")
        let task = NSURLSession.sharedSession().dataTaskWithURL(url!){
            (data, response, error) in
            
            
        }
        task.resume()
    }
    
    //UITableViewDataSource
    
    //this function returns the number of rows in the table. This number decides how
    //many time the below tableView function will be executed in order to render every 
    //cell.
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        return invitations.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) ->
        UITableViewCell{
            //the UITableViewCellStyle.Subtitle is a style for the cell. We need to change this to make it
            //fit into how we want the invitation to look in the invitation list
            let cell:InvitationTableViewCell = self.tblInvitations.dequeueReusableCellWithIdentifier("invitation_cell") as! InvitationTableViewCell
            
            if let invitationName = self.invitations[indexPath.row].invitationName{
                cell.labelInvitationName.text = invitationName
                cell.labelInvitationName.textColor = UIColor(hue: 0.6917, saturation: 1, brightness: 0.75, alpha: 1.0)
            }else{
                cell.labelInvitationName.text = "Error in title!"
            }
            cell.labelInvitationName.font = UIFont.boldSystemFontOfSize(17.0)
            
            if self.invitations[indexPath.row].changeIconVisible{
                cell.changeIcon.image = UIImage(named: "change-icon")
                cell.changeIcon.hidden = false
            }else{
                cell.changeIcon.hidden = true
            }
            
            if let eventDate = self.invitations[indexPath.row].eventDate{
                let dateFormatter = NSDateFormatter()
                dateFormatter.dateFormat = "MMM dd KK:mm aa"
                let dateString = dateFormatter.stringFromDate(eventDate)
                
                cell.labelFinalTime.text = dateString
                cell.timeIcon.image = UIImage(named: "time-icon")
                
            }else{
                cell.labelFinalTime.text = "Time voting is open!"
                cell.timeIcon.image = UIImage(named: "time-icon")
            }
            if let eventPlace = self.invitations[indexPath.row].eventPlace{
                if let eventPlaceName = eventPlace.name{
                    cell.labelFinalLocation.text = eventPlaceName
                    cell.locationIcon.image = UIImage(named: "location-icon")
                }
            }else{
                cell.labelFinalLocation.text = "Location voting is open!"
                cell.locationIcon.image = UIImage(named: "location-icon")
            }
            return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.performSegueWithIdentifier("showInvitationDetails", sender: tblInvitations)
    }
    

    // MARK: - Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let showInvitationDetailsSegueIdentifier = "showInvitationDetails"
        if segue.identifier == showInvitationDetailsSegueIdentifier {
            /*Passing invitation Id to invitation details view controller*/
            let tabBarController: UITabBarController = segue.destinationViewController as! UITabBarController

            let destinationViewController: InvitationDetailsViewController = tabBarController.viewControllers?.first as! InvitationDetailsViewController

            let destinationViewControllerComments: CommentsViewController = tabBarController.viewControllers?.last as! CommentsViewController

            
            let invitationIndex = tblInvitations.indexPathForSelectedRow?.row
            let invitationID = invitations[invitationIndex!].id
            
            
            destinationViewController.invitationID = invitationID!
            destinationViewControllerComments.invitationID = invitationID!

        }
    }
    
    //UITableView Delete
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath){
        if(editingStyle == UITableViewCellEditingStyle.Delete){
            /*If the user is host, then delete invitation. Otherwise, leave the invitation*/
            let invitation = self.invitations[indexPath.row]
            let hostId = invitation.host!.id!
            let userDic = userDataManager.getAuthenticatedUser() as! NSDictionary
            let id = userDic.valueForKey("id") as! String
            
            if let eventDate = invitation.eventDate, _ = invitation.eventPlace{
                if eventDate.timeIntervalSinceNow.isSignMinus{
                    popupMessageHandler.displayMessage("Confirm Deletion", content: "Are you sure you want to delete this invitation?", viewController: self){
                        NSLog("Archiving invitation since its final date is in the past...")
                        invitationDataManager.archiveInvitationLocally(invitation)
                    }
                }else{
                    if hostId == id{
                        popupMessageHandler.displayMessage("Confirm Deletion", content: "Are you sure you want to delete this invitation?", viewController: self){
                            if reachabilityStatus == kREACHABLEWITHWIFI || reachabilityStatus == kREACHABLEWITHWWAN{
                                invitationDataManager.deleteInvitationFromServer(self.invitations[indexPath.row].id!)
                            }else{
                                popupMessageHandler.displayInfoMessage("Cannot delete Invitation", content: "No Internet connection available.", viewController: self)
                            }
                        }
                    }else{
                        popupMessageHandler.displayMessage("Confirm Leaving", content: "Are you sure you want to exit this invitation?", viewController: self){
                            if reachabilityStatus == kREACHABLEWITHWIFI || reachabilityStatus == kREACHABLEWITHWWAN{
                                participantDataManager.deleteParticipantFromInvitationOnServer(id, invitationID: self.invitations[indexPath.row].id!)
                            }else{
                                popupMessageHandler.displayInfoMessage("Cannot leave the invitation.", content: "No Internet connection available.", viewController: self)
                            }
                        }
                    }
                }
            }else{
                if hostId == id{
                    popupMessageHandler.displayMessage("Confirm Deletion", content: "Are you sure you want to delete this invitation?", viewController: self){
                        if reachabilityStatus == kREACHABLEWITHWIFI || reachabilityStatus == kREACHABLEWITHWWAN{
                            invitationDataManager.deleteInvitationFromServer(self.invitations[indexPath.row].id!)
                        }else{
                            popupMessageHandler.displayInfoMessage("Cannot delete Invitation", content: "No Internet connection available.", viewController: self)
                        }
                    }
                }else{
                    popupMessageHandler.displayMessage("Confirm Leaving", content: "Are you sure you want to exit this invitation?", viewController: self){
                        if reachabilityStatus == kREACHABLEWITHWIFI || reachabilityStatus == kREACHABLEWITHWWAN{
                            participantDataManager.deleteParticipantFromInvitationOnServer(id, invitationID: self.invitations[indexPath.row].id!)
                        }else{
                            popupMessageHandler.displayInfoMessage("Cannot leave the invitation.", content: "No Internet connection available.", viewController: self)
                        }
                    }
                }
            }
        }
    }
    
    /*Methods for unwind segue for create new invitation*/
    @IBAction func cancelToFirstViewControl(segue:UIStoryboardSegue){
        /*Nothing happens*/
        print("cancelToFirstViewController.....")
        
    }
    
    @IBAction func submitInvitation(segue: UIStoryboardSegue){
        if reachabilityStatus == kREACHABLEWITHWIFI || reachabilityStatus == kREACHABLEWITHWWAN{
            /*Get invitation data from SecondInvitationViewController and add to Invitation object*/
            let secondViewController = segue.sourceViewController as! SecondViewController
            let titleText = secondViewController.txtTitle.text
            let newInvitation: Invitation = Invitation()
            newInvitation.invitationName = titleText
            newInvitation.possibleInvitationDates = secondViewController.possibleInvitationDates
            /*Convert friends to participants since they are to be added to the invitation*/
            var friendParticipants: [Participant] = [Participant]()
            for friendParticipant in secondViewController.participants{
                let participant: Participant = Participant()
                participant.id = friendParticipant.id
                participant.name = friendParticipant.name
                participant.userProfileImageUrl = friendParticipant.userProfileImageUrl
                participant.facebookId = friendParticipant.facebookId
                friendParticipants.append(participant)
            }
            newInvitation.participants = friendParticipants
            newInvitation.possiblePlaces = secondViewController.possiblePlaces
            /*Get logged in user from NSUserDefaults and add to Invitation*/
            if let userDic = userDataManager.getAuthenticatedUser(){
                let hostId = userDic.valueForKey("id") as? String
                let hostName = userDic.valueForKey("name") as! String
                let hostFacebookId = userDic.valueForKey("facebookId") as! String
                let host: Participant = Participant()
                host.id = hostId
                host.name = hostName
                host.userProfileImageUrl = "https://graph.facebook.com/"+hostFacebookId+"/picture"
                newInvitation.host = host
                /*send to invitation data manager for posting*/
                invitationDataManager.postInvitationToServer(newInvitation)
            }else{
                popupMessageHandler.displayInfoMessage("Cannot Post New Invitation", content: "Error getting authenticated user information.", viewController: self)
            }
        popupMessageHandler.displayInfoMessage("Cannot Post New Invitation", content: "No Internet connection available.", viewController: self)
        }
    }
    
    /*Method to handle screen refresh request & Manual connect everytime the screen is launched*/
    func refreshInivtatoinsListFromServer(){
        /*Only perform manual synchronization when there is Internet connectivity*/
        if reachabilityStatus == kREACHABLEWITHWIFI || reachabilityStatus == kREACHABLEWITHWWAN{
            if let _ = userDataManager.getAuthenticatedUser(){
                invitationDataManager.synchronizeInvitationsWithServer()
            }
        }else{
            popupMessageHandler.displayInfoMessage("Cannot Refresh Invitations", content: "No Internet connection available.", viewController: self)
        }
        self.refreshControl.endRefreshing()
    }
    
    /*Method to refresh UI*/
    func redrawUI(){
        NSLog("\(self.TAG): redrawUI")
        
        /*Configuring left menu*/
        invitations = invitationDataManager.getAllInvitations()
        
        if invitations.count < 1{
            self.emptyLabel.hidden = false
            self.tblInvitations.hidden = true
        }else{
            self.emptyLabel.hidden = true
            self.tblInvitations.hidden = false
            tblInvitations.reloadData()
        }
    }
    
    func update() {
        popupMessageHandler.displayInfoMessage("Cannot Post New Invitation", content: "You seem to have entered a meaningless invitation title.", viewController: self)
    }
    
    func isWhiteSpace(text: String) -> Bool {
        let trimmed = text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        return trimmed.isEmpty
    }
}

