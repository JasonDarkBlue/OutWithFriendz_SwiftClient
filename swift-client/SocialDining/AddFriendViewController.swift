import UIKit

class AddFriendViewController: UIViewController, UIPickerViewDelegate, UITableViewDataSource, UITableViewDelegate {
    
    var addedFriendString: String!
    var fBFriendArray: [User] = [User]()
    var fBFrinedArraySelected: [User] = [User]()
    var alreadySelectedFriends: [User] = [User]()
    
    var groupArray: [Group] = [Group]()
    
    @IBOutlet weak var friendPicker: UIPickerView!
    @IBOutlet weak var friendTableView: UITableView!
    
    let groupImage = UIImage(named:"group-icon")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /*Getting all friends from the local database*/
        fBFriendArray = userDataManager.getAllFriends()
        
        /*removing already selected friends from array of friends displayed to the user*/
        for selectedFriend in alreadySelectedFriends{
            for (index,friend) in fBFriendArray.enumerate(){
                if selectedFriend.facebookId == friend.facebookId{
                    fBFriendArray.removeAtIndex(index)
                }
            }
        }
        
        /*Getting all groups from the local database*/
        groupArray = groupDataManager.getAllGroups()

        
        let nib = UINib(nibName: "FriendCell", bundle: nil)
        friendTableView.registerNib(nib, forCellReuseIdentifier: "friend_cell")
        
        /*Register new data observer which refreshes the UI*/
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "redrawUI", name: "redrawAddFriendViewControllerScreen", object: nil)
    }
    
    //UITableView Callbacks
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fBFriendArray.count+groupArray.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell:FriendTableViewCell = self.friendTableView.dequeueReusableCellWithIdentifier("friend_cell") as! FriendTableViewCell
        if(indexPath.row<fBFriendArray.count){
            cell.friendName.text = fBFriendArray[indexPath.row].name
            cell.groupSize.hidden = true
            if reachabilityStatus == kREACHABLEWITHWIFI || reachabilityStatus == kREACHABLEWITHWWAN{
                //calling Facebook to get profile image for corresponding user
                if let urlString = fBFriendArray[indexPath.row].userProfileImageUrl{
                    let url = NSURL(string: urlString)
                    let urlRequest = NSURLRequest(URL: url!)
                    NSURLConnection.sendAsynchronousRequest(urlRequest, queue: NSOperationQueue.mainQueue()){ (response:NSURLResponse?, data:NSData?, error:NSError?) -> Void in
                        if data != nil{
                            // Display the image
                            let image = UIImage(data: data!)
                            cell.friendImage.image = image
                        }
                    }
                }
            }
        }else{
            /*Display invitation title for the group as the group name*/
            
            let group = groupArray[indexPath.row-fBFriendArray.count]
            cell.friendName.text = group.invitationName
            cell.friendImage.image = groupImage
            cell.groupSize.text = "\(group.members.count)"
            cell.friendImage.userInteractionEnabled = true
            let tapGestureRecognizer = UITapGestureRecognizer(target:self, action:#selector(AddFriendViewController.imageTapped(_:)))
            cell.friendImage.addGestureRecognizer(tapGestureRecognizer)
        }
        return cell
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        let row = indexPath.row
        switch editingStyle {
            case .Delete:
                if(row>=fBFriendArray.count){
                    groupDataManager.deleteGroupFromLocalDB(groupArray[indexPath.row-fBFriendArray.count].inviteid)
                }
            default:
                break
        }
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        if(indexPath.row<fBFriendArray.count){
            return false
        }else{
            return true
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let cell: UITableViewCell = friendTableView.cellForRowAtIndexPath(indexPath)!

        /*Code for tracking friend checkmark checked/unchecked status*/
        if (cell.accessoryType == UITableViewCellAccessoryType.Checkmark) {
            cell.accessoryType = UITableViewCellAccessoryType.None
            /*If the unselcted check is related to a friend cell, remove the friend*/
            if(indexPath.row<fBFriendArray.count){
                for (index,friend) in fBFrinedArraySelected.enumerate(){
                    if(friend.facebookId! == fBFriendArray[indexPath.row].facebookId!){
                        fBFrinedArraySelected.removeAtIndex(index)
                        break
                    }
                }
            }else{
                /*The unchecked sell is related to a group, remove group members*/
                let members = groupArray[indexPath.row-fBFriendArray.count].members
                for member in members{
                    for (index,friend) in fBFrinedArraySelected.enumerate(){
                        if(friend.facebookId! == member.facebookId!){
                            fBFrinedArraySelected.removeAtIndex(index)
                            break
                        }
                    }
                }
            }
        }else if (cell.accessoryType == UITableViewCellAccessoryType.None) {
            cell.accessoryType = UITableViewCellAccessoryType.Checkmark
            /*If the selcted check is related to a friend cell, add the friend*/
            if(indexPath.row<fBFriendArray.count){
                fBFrinedArraySelected.append(fBFriendArray[indexPath.row])
                print(fBFrinedArraySelected.count)
            }else{
                /*The checked sell is related to a group, add group members*/
                let members = groupArray[indexPath.row-fBFriendArray.count].members
                for member in members{
                    fBFrinedArraySelected.append(member)
                }
                print(fBFrinedArraySelected.count)
            }
        }
        friendTableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    /*Method to refresh the UI from local DB*/
    func redrawUI(){
        groupArray = groupDataManager.getAllGroups()
        friendTableView.reloadData()
    }
    
    func imageTapped(img: AnyObject)
    {
        let touch = img.locationInView(friendTableView)
        if let indexPath = friendTableView.indexPathForRowAtPoint(touch) {
            if(indexPath.row>=fBFriendArray.count){
                let members = groupArray[indexPath.row-fBFriendArray.count].members
                var membersNames = ""
                for member in members{
                    membersNames+=member.name!+"\n"
                }
                popupMessageHandler.displayInfoMessage("Group Members", content: membersNames, viewController: self)
            }
        }
    }

}
