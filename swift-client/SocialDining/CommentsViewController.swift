import UIKit
import JSQMessagesViewController

class CommentsViewController: JSQMessagesViewController {
    
    let TAG = "CommentsViewController"
    
    /*ID of the chosen invitation*/
    var invitationID = String()
    
    /*Local user information*/
    var userDic: NSObject?
    var hostName: String?
    var hostId: String?
    
    /*Array for svaing invitation comments retireived from local DB*/
    var commentsArray: [Comment] = [Comment]()
    
    var userName = ""
    var messages = [JSQMessage]()
    let incomingBubble = JSQMessagesBubbleImageFactory().incomingMessagesBubbleImageWithColor(UIColor(red: 10/255, green: 180/255, blue: 230/255, alpha: 1.0))
    let outgoingBubble = JSQMessagesBubbleImageFactory().outgoingMessagesBubbleImageWithColor(UIColor.lightGrayColor())

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        /*Get authenticated user information from NSUserDefaults*/
        userDic = userDataManager.getAuthenticatedUser()
        hostName = userDic!.valueForKey("name") as? String
        hostId = userDic!.valueForKey("id") as? String
        
        //To-do: check if we need this
        self.userName = hostName!
        self.senderDisplayName = hostName!
        self.senderId = hostId
        
        
        /*Register refresh UI function*/
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "redrawUI", name: "redrawCommentsScreen", object: nil)

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool){
        loadCommentsData()
    }
    
    
    /*Collection view call backs for displaying messages*/
    override func collectionView(collectionView: JSQMessagesCollectionView!, messageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageData! {
        let data = self.messages[indexPath.row]
        return data
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageBubbleImageDataSource! {
        let data = self.messages[indexPath.row]
        if (data.senderId == hostId){
            return self.outgoingBubble
        }else{
            return self.incomingBubble
        }
    }

    //To-do: display user picture
    override func collectionView(collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageAvatarImageDataSource! {
        //To-do: change the code to display proper picture
        return nil
    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.messages.count
    }
    
    //To-do: display user name and date label. For some reason this code is not working
    override func collectionView(collectionView: JSQMessagesCollectionView!, attributedTextForMessageBubbleTopLabelAtIndexPath indexPath: NSIndexPath!) -> NSAttributedString! {
        let data = self.messages[indexPath.row]
        let attString = NSAttributedString(string: data.senderDisplayName)
        return attString
    }
    
    
    override func didPressSendButton(button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: NSDate!) {
        if reachabilityStatus == kREACHABLEWITHWIFI || reachabilityStatus == kREACHABLEWITHWWAN{
            commentsDataManager.addCommentToInvitation(text, invitationID: invitationID, hostId: hostId!, hostName: hostName!)
            self.finishSendingMessage()
        }else{
            popupMessageHandler.displayInfoMessage("Cannot send your comment.", content: "No Internet connection available.", viewController: self)
        }
    }
    
    override func didPressAccessoryButton(sender: UIButton!) {
        NSLog("\(self.TAG): didPressAccessoryButton")
    }
    
    func loadCommentsData(){
        /*Get invitation comments from local database*/
        if databaseOpenHandler.open(){
            let queryCommentsSQL = "SELECT id, inviteid, content, userid, facebookname FROM COMMENT WHERE inviteid='\(invitationID)'"
            let commentResults:FMResultSet? = databaseOpenHandler.socialdiningDB!.executeQuery(queryCommentsSQL, withArgumentsInArray: nil)
            while commentResults?.next() == true {
                let comment: Comment = Comment()
                comment.id = commentResults!.stringForColumn("id")
                comment.content = commentResults!.stringForColumn("content")
                comment.userId = commentResults!.stringForColumn("userId")
                comment.userName = commentResults!.stringForColumn("facebookname")
                commentsArray.append(comment)
            }
        }
        
        /*Fill comments objects into JSQMessage required for chat client library*/
        for comment in commentsArray{
            
            var textString: String?
            if (comment.userId == hostId){
                textString = comment.content!
            }else{
                textString = "\(comment.userName!) says: \(comment.content!)"
            }
            let message = JSQMessage(senderId: comment.userId!, displayName: comment.userName!, text: textString)
            self.messages += [message]
        }
        
    }
    
    /*Method to refresh the UI of the Comments View Controller*/
    func redrawUI(){
        NSLog("\(self.TAG): redrawUI")
        commentsArray.removeAll(keepCapacity: false)
        self.messages.removeAll(keepCapacity: false)
        loadCommentsData()
        self.collectionView!.reloadData()
    }
}
