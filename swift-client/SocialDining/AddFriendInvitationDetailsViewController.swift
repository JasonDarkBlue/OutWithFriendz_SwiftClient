import UIKit

class AddFriendInvitationDetailsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    
    @IBOutlet var friendTableView: UITableView!
    
    
    var inviteid: NSString = NSString()
    var fBFriendArray: [User] = [User]()
    var participants: [Participant] = [Participant]()
    var lastSelectedIndexPath = NSIndexPath(forRow: 0, inSection: 0)
    var selectedFriend: User? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        fBFriendArray = userDataManager.getAllFriends()
        participants = participantDataManager.getListOfParticipantsForInvitationFromlocalDB(inviteid)
        /*removing already selected friends from array of friends displayed to the user*/
        for participant in participants{
            for (index,friend) in fBFriendArray.enumerate(){
                if participant.name == friend.name{
                    fBFriendArray.removeAtIndex(index)
                }
            }
        }
        
        if(fBFriendArray.count>0){
            let i=0
            selectedFriend = fBFriendArray[i]
        }
        
        let nib = UINib(nibName: "FriendCell", bundle: nil)
        friendTableView.registerNib(nib, forCellReuseIdentifier: "friend_cell")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fBFriendArray.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell:FriendTableViewCell = self.friendTableView.dequeueReusableCellWithIdentifier("friend_cell") as! FriendTableViewCell
        
        cell.friendName.text = fBFriendArray[indexPath.row].name
        cell.accessoryType = (lastSelectedIndexPath.row == indexPath.row) ? .Checkmark : .None
        if reachabilityStatus == kREACHABLEWITHWIFI || reachabilityStatus == kREACHABLEWITHWWAN{
            //calling Facebook to get profile image for corresponding user
            if let urlString = fBFriendArray[indexPath.row].userProfileImageUrl{
                let url = NSURL(string: urlString)
                let urlRequest = NSURLRequest(URL: url!)
                NSURLConnection.sendAsynchronousRequest(urlRequest, queue: NSOperationQueue.mainQueue()){ (response:NSURLResponse?, data:NSData?, error:NSError?) -> Void in
                    // Display the image
                    if data != nil{
                        let image = UIImage(data: data!)
                        cell.friendImage.image = image
                    }
                }
            }
        }
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.row != lastSelectedIndexPath.row {
            if lastSelectedIndexPath == lastSelectedIndexPath{
                let oldCell = tableView.cellForRowAtIndexPath(lastSelectedIndexPath)
                oldCell?.accessoryType = .None
            }
            
            let newCell = tableView.cellForRowAtIndexPath(indexPath)
            newCell?.accessoryType = .Checkmark
            
            lastSelectedIndexPath = indexPath
            selectedFriend = fBFriendArray[indexPath.row]
        }
    }

}
