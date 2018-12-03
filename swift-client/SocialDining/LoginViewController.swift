import UIKit


class LoginViewController: UIViewController, FBSDKLoginButtonDelegate {
    
    let TAG = "LoginViewController"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewDidAppear(animated: Bool) {
        if (FBSDKAccessToken.currentAccessToken() != nil)
        {
            // User is already logged in, do work such as go to next view controller.
            NSLog("\(self.TAG): User already logged in...")
            /******************************************************/
            /* Place where you can synchronize friends with server*/
            /******************************************************/
            
            let storyboard = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
            let firstVC = storyboard.instantiateViewControllerWithIdentifier("FirstViewController") as! FirstViewController
            
            firstVC.settingsButton.target = self.revealViewController()
            firstVC.settingsButton.action = "revealToggle:"
            firstVC.view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
            
            let navController: UINavigationController = UINavigationController(rootViewController: firstVC)
            navController.setViewControllers([firstVC], animated: true)
            self.revealViewController().setFrontViewController(navController, animated: true)
            self.revealViewController().setFrontViewPosition(FrontViewPosition.Left, animated: true)
            
            /*Sychronize user friendship information*/
            userDataManager.synchronizeFriendsPeriodically(true)
        }else{
            NSLog("\(self.TAG): showing login button...")
            let loginView : FBSDKLoginButton = FBSDKLoginButton()
            self.view.addSubview(loginView)
            loginView.center = self.view.center
            loginView.readPermissions = ["public_profile", "email", "user_friends"]
            loginView.delegate = self
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // Facebook Delegate Methods
    func loginButton(loginButton: FBSDKLoginButton!, didCompleteWithResult result: FBSDKLoginManagerLoginResult!, error: NSError!) {
        NSLog("\(self.TAG): Successful Facebook authentication...")
        /*Add user along with user information to server side*/
        userDataManager.setAuthenticatedUser(self)
        /*Go back to home screen to re-establish the effects of SWRevealViewController*/
        self.performSegueWithIdentifier("goHome", sender: nil)
        
        if ((error) != nil)
        {
            // Process error
            NSLog("\(self.TAG): Error")
        }
        else if result.isCancelled {
            // Handle cancellations
        }
        else {
            // If you ask for multiple permissions at once, you
            // should check if specific permissions missing
            if result.grantedPermissions.contains("email")
            {
                // Do work
            }
        }
    }
    
    func loginButtonDidLogOut(loginButton: FBSDKLoginButton!) {
        NSLog("\(self.TAG): User logged out...")
    }
    
    func returnUserData()
    {
        let graphRequest : FBSDKGraphRequest = FBSDKGraphRequest(graphPath: "me", parameters: nil)
        graphRequest.startWithCompletionHandler({ (connection, result, error) -> Void in
            
            if ((error) != nil)
            {
                // Process error
                NSLog("\(self.TAG): Error: \(error)")
            }
            else
            {
                NSLog("\(self.TAG): fetched user: \(result)")
                let userName : NSString = result.valueForKey("name") as! NSString
                NSLog("\(self.TAG): User Name is: \(userName)")
                let userEmail : NSString = result.valueForKey("email") as! NSString
                NSLog("\(self.TAG): User Email is: \(userEmail)")
            }
        })
    }

}
