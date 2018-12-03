import UIKit
import CoreLocation

//implementing UITextFieldDelegate is not mandatory. However, it provides some neccessary functionality such as


class SecondViewController: UIViewController, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource{

    
    @IBOutlet var txtTitle: UITextField!
    @IBOutlet var dateTableView: UITableView!
    
    var possibleInvitationDates = [PossibleInvitationDate]()
    var participants = [User]()
    var possiblePlaces = [Restaurant]()
    
    
    @IBOutlet weak var appRequestButton: UIButton!
    
    
    
    /*Variables to cache last location search information from add places screen*/
    var lastPlaceSearchQuery: NSString?
    var lastPlaceSearchResultsArray: [Restaurant]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.dateTableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "cell")
        dateTableView.editing = true
        txtTitle.autocapitalizationType = UITextAutocapitalizationType.Sentences
        let userDic = userDataManager.getAuthenticatedUser() as! NSDictionary
        let id = userDic.valueForKey("id") as! String
        userDataManager.updateUserFriendsOnServer(id)
        userDataManager.synchronizeFriendsPeriodically(true)
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func numberOfSectionsInTableView(tableView:UITableView) -> Int{
        return 3
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {

        /*Passing previous search query to AddRestaurantViewController*/
        if segue.identifier == "addRestaurantSegue"{
            if (lastPlaceSearchQuery != nil){
                let nav = segue.destinationViewController as! UINavigationController
                let addRestaurantViewController = nav.topViewController as! AddRestaurantViewController
                addRestaurantViewController.lastPlaceSearchQuery = lastPlaceSearchQuery!
                if (!(lastPlaceSearchResultsArray?.isEmpty)!){
                    addRestaurantViewController.lastPlaceSearchResultsArray = lastPlaceSearchResultsArray!
                }
                
            }
        }
        /*Passing already selected friends to AddFriendViewController*/
        if segue.identifier == "addFriendSegue"{
            let nav = segue.destinationViewController as! UINavigationController
            let addFriendViewController = nav.topViewController as! AddFriendViewController
            addFriendViewController.alreadySelectedFriends = participants
        }
    }

    
    override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
        
        if identifier == "submitInvitationUnwindSegue"{
            let inviteName = txtTitle.text
            if !isWhiteSpace(inviteName!) && inviteName!.characters.count > 2 {
                return true
            }else{
                popupMessageHandler.displayInfoMessage("Title Error!", content: "You seem to have entered a meaningless invitation title.", viewController: self)
            }
        }
        
        if identifier == "cancelInvitationUnwindSegue"{
            return true
        }
        
        return false
    }
    
    /*TableView APIs*/
    func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        
        if(indexPath.section==0 && indexPath.row==possibleInvitationDates.count){
            return UITableViewCellEditingStyle.Insert
        }
        
        if(indexPath.section==1 && indexPath.row==possiblePlaces.count){
            return UITableViewCellEditingStyle.Insert
        }
        
        if(indexPath.section==2 && indexPath.row==participants.count){
            return UITableViewCellEditingStyle.Insert
        }
        
        return UITableViewCellEditingStyle.Delete
        
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String?{
        var sectionName = String()
        
        switch (section){
        case 0:
            sectionName = "Times"
            break
        case 1:
            sectionName = "Places"
            break
        case 2:
            sectionName = "Participants"
            break
        default:
            sectionName = ""
            break
        }
        return sectionName
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var numberOfRows: Int!
        
        switch (section){
        case 0:
            numberOfRows = self.possibleInvitationDates.count+1
            break
        case 1:
            numberOfRows = self.possiblePlaces.count+1
            break
        case 2:
            numberOfRows = self.participants.count+1
            break
        default:
            break
        }
        return numberOfRows
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let section = indexPath.section
        let cell:UITableViewCell = self.dateTableView.dequeueReusableCellWithIdentifier("cell")!

        switch (section){
        case 0:
            if(indexPath.row==possibleInvitationDates.count){
                cell.textLabel?.text = ""
            } else{
                let dateFormatter = NSDateFormatter()
                dateFormatter.dateFormat = "E, MM-dd-yyyy HH:mm"
                let dateString = dateFormatter.stringFromDate(self.possibleInvitationDates[indexPath.row].eventDate!)
                cell.textLabel?.text = dateString
            }
            break
        case 1:
            if(indexPath.row==possiblePlaces.count){
                cell.textLabel?.text = ""
            } else{
                cell.textLabel?.text = self.possiblePlaces[indexPath.row].name
            }
            break
        case 2:
            if(indexPath.row==participants.count){
                cell.textLabel?.text = ""
            } else{
                cell.textLabel?.text = self.participants[indexPath.row].name
            }
            break
        default:
            break
        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        let section = indexPath.section
        _ = indexPath.row
        

        switch editingStyle {
        case .Delete:
            if(section==0){
                self.possibleInvitationDates.removeAtIndex(indexPath.row)
            }
            if(section==1){
                self.possiblePlaces.removeAtIndex(indexPath.row)
            }
            if(section==2){
                 self.participants.removeAtIndex(indexPath.row)
            }
            self.dateTableView.reloadData()
            break
        case .Insert:
            if(section==0){
                self.performSegueWithIdentifier("addDateSegue", sender: self)
            }
            if(section==1){
                if CLLocationManager.locationServicesEnabled() {
                    switch(CLLocationManager.authorizationStatus()) {
                        case .NotDetermined, .Restricted, .Denied:
                            popupMessageHandler.displayInfoMessage("Info", content: "Sorry, please go to privacy settings to enable location services for OWF.", viewController: self)
                            break
                        case .AuthorizedAlways, .AuthorizedWhenInUse:
                            self.performSegueWithIdentifier("addRestaurantSegue", sender: self)
                            break
                    }
                }else{
                    popupMessageHandler.displayInfoMessage("Info", content: "Sorry, please go to privacy settings to enable location services.", viewController: self)
                }
            }
            if(section==2){
                self.performSegueWithIdentifier("addFriendSegue", sender: self)
            }
        default:
            break
        }
    }
    
    /*Unwind AddDateViewController*/
    @IBAction func cancelToAddDateViewController(segue:UIStoryboardSegue) {
        /*Nothing happens*/
    }
    
    @IBAction func saveDate(segue:UIStoryboardSegue) {
        /*Save date possibleInvitationDates list & refresh UI*/
        let addDateViewController = segue.sourceViewController as! AddDateViewController
        possibleInvitationDates.append(addDateViewController.newPossibleInvitationDate)
        dateTableView.reloadData()
    }
    
    /*Unwind AddFriendViewController*/
    @IBAction func cancelToAddFriendViewController(segue:UIStoryboardSegue) {
        /*Nothing happens*/
    }
    
    @IBAction func saveFriend(segue:UIStoryboardSegue) {
        let addFriendViewController = segue.sourceViewController as! AddFriendViewController
        
        /*Removing duplicate users due to adding groups and friends*/
        let toBeAddedFriendsWithDupliactes = addFriendViewController.fBFrinedArraySelected
        var toBeAddedFriends: [User] = [User]()
        var addedIds: [String] = [String]()
        
        for friend in toBeAddedFriendsWithDupliactes{
            if !addedIds.contains(friend.facebookId!){
                addedIds.append(friend.facebookId!)
                toBeAddedFriends.append(friend)
            }
        }
        
        /*Avoiding adding the same user twice*/
        print("Participants size: \(participants.count)")
        var participantsIds: [String] = [String]()
        
        for participant in participants{
            participantsIds.append(participant.facebookId!)
        }
        
        for friend in toBeAddedFriends{
            if !participantsIds.contains(friend.facebookId!){
                participants.append(friend)
            }
        }
        dateTableView.reloadData()
    }

    /*Unwind AddRestaurantViewController*/
    @IBAction func saveRestaurant(segue:UIStoryboardSegue) {
        let addRestaurantViewController = segue.sourceViewController as! AddRestaurantViewController
        /*Ensure name and place_id coming from Google are not empty*/
        if let _ = addRestaurantViewController.newRest.placeId, let _ = addRestaurantViewController.newRest.name{
            possiblePlaces.append(addRestaurantViewController.newRest)
            lastPlaceSearchQuery = addRestaurantViewController.searchTextField.text
            lastPlaceSearchResultsArray = addRestaurantViewController.lastPlaceSearchResultsArray
            dateTableView.reloadData()
        }
    }
    
    /*Unwind AddRestaurantViewController methods*/
    @IBAction func cancelToAddRestaurantViewController(segue:UIStoryboardSegue) {
        /*Clear last cached search*/
        lastPlaceSearchQuery = nil
        lastPlaceSearchResultsArray = nil
    }
    
    //this function will remove the keyboard in case the user clicked anywhere on screen
    //or the add button
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    //UITextField Delegate
    //This function causes the keyboard to go away when the user clicks the enter button
    func textFieldShouldReturn(textField: UITextField) -> Bool{
        textField.resignFirstResponder();//the first responder is the keyboard and this cause it to go away
        return true
    }
    
    func isWhiteSpace(text: String) -> Bool {
        let trimmed = text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        return trimmed.isEmpty
    }
    
    func uniq<S : SequenceType, T : Hashable where S.Generator.Element == T>(source: S) -> [T] {
        var buffer = [T]()
        var added = Set<T>()
        for elem in source {
            if !added.contains(elem) {
                buffer.append(elem)
                added.insert(elem)
            }
        }
        return buffer
    }
    
}

