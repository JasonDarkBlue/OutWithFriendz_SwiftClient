import UIKit
import MessageUI
import Social

extension BackTableViewController: FBSDKAppInviteDialogDelegate{
    func appInviteDialog(appInviteDialog: FBSDKAppInviteDialog!, didCompleteWithResults results: [NSObject : AnyObject]!) {
        //TODO
    }
    func appInviteDialog(appInviteDialog: FBSDKAppInviteDialog!, didFailWithError error: NSError!) {
        //TODO
    }
}

class BackTableViewController: UITableViewController, MFMailComposeViewControllerDelegate{

    
    var tableArray = [String]()
    
    /*Variables holding user information from NSUserDefaults*/
    var userDic: NSObject?
    var hostName: String?
    var hostId: String?
    var facebookId: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableArray = ["Share OutWithFriendz","Contact Us","Share FB","Contact Us", "More"]
        
        let nibAppName = UINib(nibName: "AppNameCell", bundle: nil)
        self.tableView.registerNib(nibAppName, forCellReuseIdentifier: "app_name_cell")
        
        let nibInviteFriends = UINib(nibName: "InviteFriends", bundle: nil)
        self.tableView.registerNib(nibInviteFriends, forCellReuseIdentifier: "invite_friends_cell")
        
        let nibLogout = UINib(nibName: "LogoutCell", bundle: nil)
        self.tableView.registerNib(nibLogout, forCellReuseIdentifier: "logout_cell")
        
        let nibAuthenticatedUser = UINib(nibName: "AuthenticatedUserCell", bundle: nil)
        self.tableView.registerNib(nibAuthenticatedUser, forCellReuseIdentifier: "authenticated_user_cell")
        
        let nibContactUs = UINib(nibName: "ContactUsCell", bundle: nil)
        self.tableView.registerNib(nibContactUs, forCellReuseIdentifier: "contact_us_cell")
        
        let nibShare = UINib(nibName: "ShareCell", bundle: nil)
        self.tableView.registerNib(nibShare, forCellReuseIdentifier: "share_cell")
        
        
        
        /*Get authenticated user information from NSUserDefaults*/
        userDic = userDataManager.getAuthenticatedUser()
        hostName = userDic!.valueForKey("name") as? String
        hostId = userDic!.valueForKey("id") as? String
        facebookId = userDic!.valueForKey("facebookId") as? String
        
        
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 7
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell :UITableViewCell!

        // Configure the cell...
        switch (indexPath.row){
        /*Application name cell*/
         case 0:
            cell = tableView.dequeueReusableCellWithIdentifier("app_name_cell", forIndexPath: indexPath) as! AppNameTableViewCell
            cell.selectionStyle = UITableViewCellSelectionStyle.None
            break
            
        /*User profile information cell*/
        case 1:
            cell = tableView.dequeueReusableCellWithIdentifier("authenticated_user_cell", forIndexPath: indexPath) as! AuthenticatedUserTableViewCell
            /*Getting user Profile Image from Facebook*/
            if reachabilityStatus == kREACHABLEWITHWIFI || reachabilityStatus == kREACHABLEWITHWWAN{
                if(facebookId != nil){
                    let urlString: String = "http://graph.facebook.com/\(facebookId!)/picture?type=large"
                    let url = NSURL(string: urlString)
                    let urlRequest = NSURLRequest(URL: url!)
                    NSURLConnection.sendAsynchronousRequest(urlRequest, queue: NSOperationQueue.mainQueue()){ (response:NSURLResponse?, data:NSData?, error:NSError?) -> Void in
                        // Display the image
                        if data != nil{
                            let image = UIImage(data: data!)
                            (cell as! AuthenticatedUserTableViewCell).userImage.image = image
                        }
                    }
                }
            }
            if(hostName != nil){
                (cell as! AuthenticatedUserTableViewCell).userNameLabel.text = hostName!
                (cell as! AuthenticatedUserTableViewCell).userNameLabel.textColor = UIColor(hue: 0.6917, saturation: 1, brightness: 0.75, alpha: 1.0)

            }else{
                (cell as! AuthenticatedUserTableViewCell).userNameLabel.text = "Error!"
            }
            cell.selectionStyle = UITableViewCellSelectionStyle.None
            break
        /*invite friends through Facebook*/
        case 2:
            cell = tableView.dequeueReusableCellWithIdentifier("logout_cell") as! LogoutCellTableViewCell
            let inviteFriendsImage = UIImage(named:"invite-icon")
            (cell as! LogoutCellTableViewCell).cellImage.image = inviteFriendsImage
            (cell as! LogoutCellTableViewCell).cellLabel.text = "Invite Friends"
            break
        /*Share app through Facebook cell*/
        case 3:
            cell = tableView.dequeueReusableCellWithIdentifier("share_cell", forIndexPath: indexPath) as! ShareTableViewCell
            let shareImage = UIImage(named:"facebook-logo-icon")
            (cell as! ShareTableViewCell).shareImage.image = shareImage
            (cell as! ShareTableViewCell).shareText.text = "Post to Facebook"
            break
        
        /*Share app through Emails*/
        case 4:
            cell = tableView.dequeueReusableCellWithIdentifier("share_cell", forIndexPath: indexPath) as! ShareTableViewCell
            let shareEmailImage = UIImage(named:"facebook-share-icon")
            (cell as! ShareTableViewCell).shareImage.image = shareEmailImage
            (cell as! ShareTableViewCell).shareText.text = "Share App!"
            break
            
        /*Contact us cell*/
        case 5:
            cell = tableView.dequeueReusableCellWithIdentifier("contact_us_cell", forIndexPath: indexPath) as! ContactUsTableViewCell
            let contactUsImage = UIImage(named:"contact-us-icon")
            (cell as! ContactUsTableViewCell).contacUsImage.image = contactUsImage
            break
            
            /*Logout cell*/
        case 6:
            cell = self.tableView.dequeueReusableCellWithIdentifier("logout_cell") as! LogoutCellTableViewCell
            let facebookImage = UIImage(named:"facebook-icon-logout")
            (cell as! LogoutCellTableViewCell).cellImage.image = facebookImage
            (cell as! LogoutCellTableViewCell).cellLabel.text = "Logout"
            break
            
         default:
            
            cell = tableView.dequeueReusableCellWithIdentifier("app_name_cell", forIndexPath: indexPath) as! AppNameTableViewCell
            cell.selectionStyle = UITableViewCellSelectionStyle.None
            
            break
            
        }

        return cell
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        switch (indexPath.row){
        case 2:
            inviteFriends()
            break
        case 3:
            shareToFacebook()
            break
        case 4:
            shareByEmail()
            break
        case 5:
            contactUs()
            break
        case 6:
            logout()
            break
        default:
            break
        }
    }
    
    func shareByEmail(){
        if MFMailComposeViewController.canSendMail(){
            let mail = MFMailComposeViewController()
            mail.mailComposeDelegate = self
            mail.setSubject("Share OutWithFriendz App")
            mail.setMessageBody("Sent from OutWithFriendz. Get the App - https://itunes.apple.com/bm/app/outwithfriendz/id1050504914?mt=8", isHTML: false)
            presentViewController(mail, animated: true, completion: nil)
            
        }else{
            showSendMailErrorAlert()
        }
        
    }
    
    
    
    func inviteFriends(){
        let content = FBSDKAppInviteContent()
        content.appLinkURL = NSURL(string: "https://fb.me/1821703181385635")
        content.appInvitePreviewImageURL = NSURL(string: "http://a4.mzstatic.com/us/r30/Purple2/v4/ff/c6/6c/ffc66c38-22ad-90d3-ee52-4aca8acc713b/icon175x175.png")
        FBSDKAppInviteDialog.showFromViewController(self, withContent: content, delegate: self)
        
    }
    
    func shareToFacebook(){
        if(SLComposeViewController.isAvailableForServiceType(SLServiceTypeFacebook)){
            var facebookSheet: SLComposeViewController = SLComposeViewController(forServiceType: SLServiceTypeFacebook)
            facebookSheet.setInitialText("Go OutWithFriendz! Create an event and add times and Google places to it. Then, invite friends and let the group vote on when and where to meet. It's easy!")
            facebookSheet.addURL(NSURL(string: "https://itunes.apple.com/mg/app/outwithfriendz/id1050504914?mt=8"))
            self.presentViewController(facebookSheet, animated: true, completion: nil)
        }else{
            popupMessageHandler.displayInfoMessage("Error!", content: "Sharing function is not available for this account.", viewController: self)
        }
    }
    
    func contactUs(){
        print("contactUs menu clicked", terminator: "")
        let mailComposeViewController = configuredMailComposeViewController()
        if MFMailComposeViewController.canSendMail() {
            self.presentViewController(mailComposeViewController, animated: true, completion: nil)
        } else {
            self.showSendMailErrorAlert()
        }
    }
    
    func logout(){
        let loginManager = FBSDKLoginManager()
        loginManager.logOut()
        /*Routing user to login page*/
        let loginPage = self.storyboard?.instantiateViewControllerWithIdentifier("LoginViewController") as! LoginViewController
        let loginPageNav = UINavigationController(rootViewController: loginPage)
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        appDelegate.window?.rootViewController = loginPageNav
        NSUserDefaults.standardUserDefaults().setBool(true, forKey: "Logout")
    }
    
    func configuredMailComposeViewController() -> MFMailComposeViewController {
        let mailComposerVC = MFMailComposeViewController()
        mailComposerVC.mailComposeDelegate = self // Extremely important to set the --mailComposeDelegate-- property, NOT the --delegate-- property
        
        mailComposerVC.setToRecipients(["out.with.friendz@gmail.com"])
        mailComposerVC.setSubject("OutWithFriendz feedback")
        
        return mailComposerVC
    }
    
    func showSendMailErrorAlert() {
        let sendMailErrorAlert = UIAlertView(title: "Could Not Send Email", message: "Your device could not send e-mail.  Please check e-mail configuration and try again.", delegate: self, cancelButtonTitle: "OK")
        sendMailErrorAlert.show()
    }
    
    // MARK: MFMailComposeViewControllerDelegate Method
    func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {
        controller.dismissViewControllerAnimated(true, completion: nil)
    }

}