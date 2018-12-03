import UIKit
import CoreData
import CoreLocation
import Foundation


/*Variable for handling network reachability for the application*/
/*Defined outside of the AppDelegate class to be accessed globally throught the app*/
let kREACHABLEWITHWIFI = "ReachabilityWithWIFI"
let kNOTREACHABLE = "NotReachable"
let kREACHABLEWITHWWAN = "ReachableWithWWAN"

var reachability: Reachability?
var reachabilityStatus = kREACHABLEWITHWIFI

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, CLLocationManagerDelegate, GGLInstanceIDDelegate{

    let TAG = "AppDelegate"
    
    var window: UIWindow?
    var tokenString: String?
    var connectedToGCM: Bool = false
    var registrationOptions = [String: AnyObject]()
    
    
    var activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView()
    var locationManager: CLLocationManager = CLLocationManager()
    var internetReach: Reachability?
    
    /*Key description: Key for iOS applications*/
    let googleMapsApiKey = "AIzaSyA5epcTHNim9ieiixj44oTcP3KV0vTg1gY"

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        NSLog("<-->AppDelegate: didFinishLaunchingWithOptions")
        
        // Override point for customization after application launch.
        let navigationBarAppearace = UINavigationBar.appearance()
        
        //navigationBarAppearace.tintColor = UIColor(hue: 0.0611, saturation: 1, brightness: 0.97, alpha: 1.0)
        navigationBarAppearace.barTintColor = UIColor(hue: 0.0806, saturation: 0.97, brightness: 1, alpha: 1.0)
        //self.navigationController?.navigationBar.tintColor = UIColor(hue: 0.1083, saturation: 1, brightness: 0.92, alpha: 1.0)
        UIBarButtonItem.appearance().tintColor = UIColor.whiteColor()
        navigationBarAppearace.tintColor = UIColor.whiteColor()
        // change navigation item title color
        //navigationBarAppearace.titleTextAttributes =
        
        /*Creating SQLite database and tables in case they don't exist*/
        let filemgr = NSFileManager.defaultManager()
        let dirPaths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
        let docsDir = dirPaths[0] 
        //let databasePath = docsDir.stringByAppendingPathComponent("socialdining.db")
        let databasePath = (docsDir as NSString).stringByAppendingPathComponent("socialdining.db")
        if !filemgr.fileExistsAtPath(databasePath as String){
            NSLog("Creating database along with tables...")
            let socialdiningDB = FMDatabase(path: databasePath as String)
            
            if socialdiningDB == nil {
                print("Error: \(socialdiningDB.lastErrorMessage())")
                NSLog("Error: %@", socialdiningDB.lastErrorMessage())
            }
            
            if socialdiningDB.open(){
                /*Creatin SQLite database tables*/
                /*User domain object table*/
                let userTableCreateStatament = "CREATE TABLE IF NOT EXISTS USER (id TEXT, name TEXT, facebookId TEXT, userProfileImageUrl TEXT)"
                if !socialdiningDB.executeStatements(userTableCreateStatament){
                    print("Error: \(socialdiningDB.lastErrorMessage())")
                }
                /*Invitation domain object table*/
                let invitationTableCreateStatament = "CREATE TABLE IF NOT EXISTS INVITATION (id TEXT PRIMARY KEY, invitationName TEXT, hostId TEXT, eventDate INTEGER, eventPlace TEXT, archived INTEGER DEFAULT 0, changeIconVisible INTEGER DEFAULT 0)"
                if !socialdiningDB.executeStatements(invitationTableCreateStatament){
                    print("Error: \(socialdiningDB.lastErrorMessage())")
                }
                /*PossibleInvitationDate domain object table*/
                let possibleInvitationDateTableCreateStatament = "CREATE TABLE IF NOT EXISTS POSSIBLE_INVITATION_DATE (id TEXT PRIMARY KEY, inviteid TEXT,eventDate INTEGER)"
                if !socialdiningDB.executeStatements(possibleInvitationDateTableCreateStatament){
                    print("Error: \(socialdiningDB.lastErrorMessage())")
                }
                
                /*Participant domain object table*/
                let participantTableCreateStatament = "CREATE TABLE IF NOT EXISTS PARTICIPANT (id TEXT, name TEXT, inviteid TEXT, userProfileImageUrl TEXT)"
                if !socialdiningDB.executeStatements(participantTableCreateStatament){
                    print("Error: \(socialdiningDB.lastErrorMessage())")
                }
                
                /*Place domain object table*/

                let placeTableCreateStatament = "CREATE TABLE IF NOT EXISTS PLACE (id TEXT PRIMARY KEY, name TEXT, inviteid TEXT, place_id TEXT, vicinity TEXT, description TEXT, userId TEXT)"
                if !socialdiningDB.executeStatements(placeTableCreateStatament){
                    print("Error: \(socialdiningDB.lastErrorMessage())")
                }
                
                /*PossibleInvitationDateVote domain object table*/
                let possibleInvitationDateVoteTableCreateStatament = "CREATE TABLE IF NOT EXISTS POSSIBLE_INVITATION_DATE_VOTE (id TEXT, inviteid TEXT, possible_invitation_date_id TEXT, userid TEXT, facebookname TEXT)"
                if !socialdiningDB.executeStatements(possibleInvitationDateVoteTableCreateStatament){
                    print("Error: \(socialdiningDB.lastErrorMessage())")
                }
                
                /*PlaceVote domain object table*/
                let placeVoteTableCreateStatament = "CREATE TABLE IF NOT EXISTS PLACE_VOTE (id TEXT, inviteid TEXT, place_id TEXT, userid TEXT, facebookname TEXT)"
                if !socialdiningDB.executeStatements(placeVoteTableCreateStatament){
                    print("Error: \(socialdiningDB.lastErrorMessage())")
                }
                
                /*Comment domain object table*/
                let commentTableCreateStatament = "CREATE TABLE IF NOT EXISTS COMMENT (id TEXT, inviteid TEXT, content TEXT, userid TEXT, facebookname TEXT)"
                if !socialdiningDB.executeStatements(commentTableCreateStatament){
                    print("Error: \(socialdiningDB.lastErrorMessage())")
                }
                
                /*TO-DO: create table GROUP: members*/
                let groupTableCreateStatament = "CREATE TABLE IF NOT EXISTS GROUPLIST (list TEXT, names TEXT, inviteid TEXT, invitationName TEXT)"
                if !socialdiningDB.executeStatements(groupTableCreateStatament){
                    print("Error: \(socialdiningDB.lastErrorMessage())")
                }
                
                socialdiningDB.close()
            } else{
                print("Error: \(socialdiningDB.lastErrorMessage())")
            }
            
        }
        
        /*Register for remote notifications and obtain an APNS token*/
        let types: UIUserNotificationType = [UIUserNotificationType.Badge, UIUserNotificationType.Alert, UIUserNotificationType.Sound]
        let settings: UIUserNotificationSettings = UIUserNotificationSettings( forTypes: types, categories: nil )
        application.registerUserNotificationSettings( settings )
        application.registerForRemoteNotifications()
        
        /*Configure location manager to receive location changes in the background*/
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        /*Configuring the internet reach class to keep listening for network status changes when the app is launched*/
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "reachabilityChanged:", name: kReachabilityChangedNotification, object: nil)
        
        internetReach = Reachability.reachabilityForInternetConnection()
        internetReach?.startNotifier()
        if internetReach != nil{
            self.statusChangedWithReachability(internetReach!)
        }
        
        return FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    func reachabilityChanged(notification: NSNotification){
        NSLog("Reachability status changed...")
        if let reachability = notification.object as? Reachability{
            self.statusChangedWithReachability(reachability)
        }
    }
    
    func statusChangedWithReachability(currentReachabilityStatus: Reachability){
        let networkStatus: NetworkStatus = currentReachabilityStatus.currentReachabilityStatus()
        NSLog("Status values: \(networkStatus.rawValue)")
        if networkStatus.rawValue == NotReachable.rawValue{
            NSLog("Network not reachable..")
            reachabilityStatus = kNOTREACHABLE
        }else if networkStatus.rawValue == ReachableViaWiFi.rawValue{
            NSLog("Network Reachable Via WiFi..")
            reachabilityStatus = kREACHABLEWITHWIFI
        }else if networkStatus.rawValue == ReachableViaWWAN.rawValue{
            NSLog("Network Reachable Via WWAN..")
            reachabilityStatus = kREACHABLEWITHWWAN
        }
        NSNotificationCenter.defaultCenter().postNotificationName("ReachStatusChanged", object: nil)
    }
    
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        NSLog("<-->AppDelegate: didRegisterForRemoteNotificationsWithDeviceToken")
        
        NSLog("Received new push notification token.")
        // Create a config and set a delegate that implements the GGLInstaceIDDelegate protocol.
        let instanceIDConfig = GGLInstanceIDConfig.defaultConfig()

        instanceIDConfig.delegate = self
        
        GGLInstanceID.sharedInstance().startWithConfig(GGLInstanceIDConfig.defaultConfig())
        
        /*the kGGLInstanceIDAPNSServerTypeSandboxOption is set to true to indicate that the configuration is meant for development stage*/
        registrationOptions = [kGGLInstanceIDRegisterAPNSOption:deviceToken, kGGLInstanceIDAPNSServerTypeSandboxOption:false]
        
        activityIndicator.center = self.window!.rootViewController!.view.center
        self.window?.rootViewController?.view.addSubview(activityIndicator)
        UIApplication.sharedApplication().beginIgnoringInteractionEvents()
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        activityIndicator.hidden = false
        activityIndicator.startAnimating()
        GGLInstanceID.sharedInstance().tokenWithAuthorizedEntity(Config.GCM_SENDER_ID, scope: kGGLInstanceIDScopeGCM, options: registrationOptions){
                (registrationToken, error) -> Void in
            if error != nil{
                print("There error is:")
                print(error)
            } else{
                NSLog("Received GCM registeration token...")
                self.tokenString = registrationToken
                self.connectToGCM()
                self.activityIndicator.stopAnimating()
                self.activityIndicator.hidden = true
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                UIApplication.sharedApplication().endIgnoringInteractionEvents()
            }
        }
    }
    
    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
        NSLog("<-->AppDelegate: didFailToRegisterForRemoteNotificationsWithError")
        
        NSLog("APN Registeration Error: \(error.localizedDescription)")
    }
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
        NSLog("<-->AppDelegate: didReceiveRemoteNotification")
        
        NSLog("Notification received: \(userInfo)")
        // This works only if the app started the GCM service
        GCMService.sharedInstance().appDidReceiveMessage(userInfo);
        // Handle the received message
        // ...

        let messageDic = userInfo as NSDictionary
        
        for (key, _) in messageDic{
            let valueString = messageDic.valueForKey(key as! String) as! NSString
            if(key as! String=="newInvitation invitationId"){
                NSLog("GCM update: new invitation...")
                invitationDataManager.synchronizeInvitationsWithServer()
            }
            if(key as! String=="updatedInvitation invitationId"){
                NSLog("GCM update: update invitation information...")
                invitationDataManager.sychronizeInvitationWithServerById(valueString as String)
            }
            if(key as! String=="newPossibleInvitationDateVote invitationId"){
                NSLog("GCM update: add new PossibleInvitationDateVote...")
                //possibleInvitationDateVoteDataManager.sychronizeInvitationDateVotesWithServerById(valueString as String, addFlag: true)
                let invitationId = valueString as String
                possibleInvitationDateVoteDataManager.copyInvitationDateVotesFromServerById(invitationId)
            }
            if(key as! String=="deletedPossibleInvitationDateVote invitationId"){
                NSLog("GCM update: delete existing PossibleInvitationDateVote...")
                //possibleInvitationDateVoteDataManager.sychronizeInvitationDateVotesWithServerById(valueString as String, addFlag: false)
                possibleInvitationDateVoteDataManager.copyInvitationDateVotesFromServerById(valueString as String)
            }
            if(key as! String=="newPlaceVote invitationId"){
                NSLog("GCM update: add new PlaceVote...")
                //placeVoteDataManager.sychronizeInvitationPlaceVotesWithServerById(valueString as String, addFlag: true)
                placeVoteDataManager.copyInvitationPlaceVotesFromServerById(valueString as String)
                
            }
            if(key as! String=="deletedPlaceVote invitationId"){
                NSLog("GCM update: delete existing PlaceVote...")
                //placeVoteDataManager.sychronizeInvitationPlaceVotesWithServerById(valueString as String, addFlag: false)
                placeVoteDataManager.copyInvitationPlaceVotesFromServerById(valueString as String)
            }
            if(key as! String=="newComment invitationId"){
                NSLog("GCM update: add new Comment......")
                commentsDataManager.sychronizeInvitationCommentsWithServerById(valueString as String)
            }
            if(key as! String=="deletedInvitation invitationId"){
                NSLog("GCM update: delete an Invitation......")
                invitationDataManager.deleteInvitationFromLocalDB(valueString as String)
                
            }
            if((key as! NSString).containsString("newUser")){
                NSLog("GCM update: new friend......")
                userDataManager.synchronizeFriendsPeriodically(true)
            }
        }
    }
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject], fetchCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
        NSLog("<-->AppDelegate: didReceiveRemoteNotification-fetchCompletionHandler")
        NSLog("Notification received-lengthy: \(userInfo)")
        // This works only if the app started the GCM service
        GCMService.sharedInstance().appDidReceiveMessage(userInfo);
        // Handle the received message
        // Invoke the completion handler passing the appropriate UIBackgroundFetchResult value
        // ...
    }
    
    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool {
        NSLog("<-->AppDelegate: openURL")
        return FBSDKApplicationDelegate.sharedInstance().application(application, openURL: url, sourceApplication: sourceApplication, annotation: annotation)
    }

    func applicationWillResignActive(application: UIApplication) {
        NSLog("<-->AppDelegate: applicationWillResignActive")
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        NSLog("<-->AppDelegate: applicationDidEnterBackground")
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        self.locationManager.delegate = self
        locationManager.startMonitoringSignificantLocationChanges()
    }

    func applicationWillEnterForeground(application: UIApplication) {
        NSLog("<-->AppDelegate: applicationWillEnterForeground")
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        application.beginBackgroundTaskWithExpirationHandler{}
        locationManager.stopMonitoringSignificantLocationChanges()
    }

    func applicationDidBecomeActive(application: UIApplication) {
        NSLog("<-->AppDelegate: applicationDidBecomeActive")
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        FBSDKAppEvents.activateApp()
        if reachabilityStatus == kREACHABLEWITHWIFI || reachabilityStatus == kREACHABLEWITHWWAN{
            if let tokenStr = tokenString{
                NSLog("token is: \(tokenStr)")
                GGLInstanceID.sharedInstance().tokenWithAuthorizedEntity(Config.GCM_SENDER_ID, scope: kGGLInstanceIDScopeGCM, options: registrationOptions){
                    (registrationToken, error) -> Void in
                    if error != nil{
                        NSLog("Launch registeration failed:")
                        NSLog(error.localizedDescription)
                    } else{
                        NSLog("Successfull performed launch registeration...")
                        NSLog(registrationToken)
                        self.tokenString = registrationToken
                        /*Refresh GCM registeration token on server*/
                        NSLog("\(self.TAG): Start: post GCM registeration token")
                        if let userDic = userDataManager.getAuthenticatedUser() as? NSDictionary{
                            let hostID = userDic.valueForKey("id") as! String
                            let postGCMRegisterationIdRequest = NSMutableURLRequest(URL: NSURL(string: Config.SERVER_URL+"/users/"+hostID+"/androidGCMRegistrationId")!)
                            let session = NSURLSession.sharedSession()
                            postGCMRegisterationIdRequest.HTTPMethod = "PUT"
                            let data = registrationToken.dataUsingEncoding(NSUTF8StringEncoding)
                            postGCMRegisterationIdRequest.HTTPBody = data
                            postGCMRegisterationIdRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
                            postGCMRegisterationIdRequest.addValue("application/json", forHTTPHeaderField: "Accept")
                            NSLog("\(self.TAG): HttpPost: post GCM registration ID")
                            let postGCMRegisterationIdTask = session.dataTaskWithRequest(postGCMRegisterationIdRequest, completionHandler: {data, response, error -> Void in
                                do {
                                    if let data = data{
                                        let _ = try NSJSONSerialization.JSONObjectWithData(data, options: [])
                                        NSLog("\(self.TAG): HttpPost: Successfuly posted GCM registration ID to server...")
                                    }
                                } catch {
                                    // failure
                                    NSLog("\(self.TAG): HttpPost: Error: \((error as NSError).localizedDescription)")
                                }
                            })
                            postGCMRegisterationIdTask.resume()
                        }
                    }
                }
            }else{
                NSLog("No token available yet...")
            }

        }else{
            print("No internet connection")
            
        }
            
        
        self.connectToGCM()
        application.beginBackgroundTaskWithExpirationHandler{}
        // Reset the application badge to zero when the application as launched. The notification is viewed.
        if application.applicationIconBadgeNumber > 0 {
            application.applicationIconBadgeNumber = 0
        }
        userDataManager.synchronizeFriendsPeriodically(true)
    }

    func applicationWillTerminate(application: UIApplication) {
        print("<-->AppDelegate: applicationWillTerminate")
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        self.saveContext()
        application.beginBackgroundTaskWithExpirationHandler{}
        
        /*Stop observing network reachability changes*/
        NSNotificationCenter.defaultCenter().removeObserver(self, name: kReachabilityChangedNotification, object: nil)
    }
    
    func connectToGCM(){
        let gcmService = GCMService.sharedInstance()
        gcmService.startWithConfig(GCMConfig.defaultConfig())
        gcmService.connectWithHandler{
            error -> Void in
            if error != nil{
                NSLog("Could not connect to GCM: \(error.localizedDescription)")
                print("The GCM registration token needs to be refreshed.")
                
            } else{
                NSLog("Connected successfuly to GCM...")
                
                self.connectedToGCM = true
            }
            GGLInstanceID.sharedInstance().tokenWithAuthorizedEntity(Config.GCM_SENDER_ID, scope: kGGLInstanceIDScopeGCM, options: self.registrationOptions, handler: self.registrationHandler)
        }
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        var bgTask = UIBackgroundTaskIdentifier()
        bgTask = UIApplication.sharedApplication().beginBackgroundTaskWithExpirationHandler { () -> Void in
            UIApplication.sharedApplication().endBackgroundTask(bgTask)
        }
        
        if let location = manager.location{
            NSLog("Putting loc: \(location.coordinate.latitude):\(location.coordinate.longitude)")
            /*Only post location if user is authenticated*/
            if reachabilityStatus == kREACHABLEWITHWIFI || reachabilityStatus == kREACHABLEWITHWWAN{
                if let userDic = userDataManager.getAuthenticatedUser(){
                    /*Prepare location information for posting*/
                    let locationParameters:  NSMutableDictionary = NSMutableDictionary()
                    locationParameters.setObject(location.coordinate.latitude, forKey: "lat")
                    locationParameters.setObject(location.coordinate.longitude, forKey: "lon")
                    /*Prepare HTTP POST request for sending location information to the server*/
                    let hostId = userDic.valueForKey("id") as? String
                    let request = NSMutableURLRequest(URL: NSURL(string: Config.SERVER_URL+"/users/"+hostId!+"/location")!)
                    let session = NSURLSession.sharedSession()
                    request.HTTPMethod = "PUT"
                    var err: NSError?
                    do {
                        request.HTTPBody = try NSJSONSerialization.dataWithJSONObject(locationParameters, options: [])
                    } catch let error as NSError {
                        err = error
                        print(err?.localizedDescription)
                        request.HTTPBody = nil
                    }
                    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.addValue("application/json", forHTTPHeaderField: "Accept")
                    /*Invoke the HTTP POST request*/
                    let task = session.dataTaskWithRequest(request, completionHandler: {data, response, error -> Void in
                        do {
                            //@_@ to do
                            let _ = try NSJSONSerialization.JSONObjectWithData(data!, options: [])
                            NSLog("Successfuly posted user location to server...")
                        } catch {
                            // failure
                            NSLog("\(self.TAG): \((error as NSError).localizedDescription)")
                        }
                    })
                    task.resume()
                }else{
                    print("No authenticated user found during location post...")
                }
            }else{
                print("No Internet connection available.")
                
            }
        }
        
        if (bgTask != UIBackgroundTaskInvalid)
        {
            UIApplication.sharedApplication().endBackgroundTask(bgTask);
            bgTask = UIBackgroundTaskInvalid;
        }
    }
    // MARK: - Core Data stack
    
    lazy var applicationDocumentsDirectory: NSURL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "com.xxxx.ProjectName" in the application's documents Application Support directory.
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls[urls.count-1] 
        }()
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = NSBundle.mainBundle().URLForResource("Model", withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
        }()
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
        // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        var coordinator: NSPersistentStoreCoordinator? = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("SocialDining.sqlite")
        var error: NSError? = nil
        do {
            try coordinator!.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: nil)
        } catch var error1 as NSError {
            error = error1
            coordinator = nil
            // Report any error we got.
            error = NSError(domain: "edu.colorado.socialfusion.socialdining", code: 9999, userInfo: nil)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(error), \(error!.userInfo)")
            abort()
        } catch {
            fatalError()
        }
        
            return coordinator
        }()
    
    lazy var managedObjectContext: NSManagedObjectContext? = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        if coordinator == nil {
            return nil
        }
        var managedObjectContext = NSManagedObjectContext()
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
        }()
    
    // MARK: - Core Data Saving support
    func saveContext () {
        if let moc = self.managedObjectContext {
            var error: NSError? = nil
            if moc.hasChanges {
                do {
                    try moc.save()
                } catch let error1 as NSError {
                    error = error1
                    // Replace this implementation with code to handle the error appropriately.
                    // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                    NSLog("Unresolved error \(error), \(error!.userInfo)")
                    abort()
                }
            }
        }
    }

    
    func registrationHandler(registrationToken: String!, error: NSError!) {
        //Update the new GCM registeration token on server side
        self.tokenString = registrationToken
        /*Refresh GCM registeration token on server*/
        NSLog("\(self.TAG): Start: post GCM registeration token")
        if let userDic = userDataManager.getAuthenticatedUser() as? NSDictionary{
            let hostID = userDic.valueForKey("id") as! String
            let postGCMRegisterationIdRequest = NSMutableURLRequest(URL: NSURL(string: Config.SERVER_URL+"/users/"+hostID+"/androidGCMRegistrationId")!)
            let session = NSURLSession.sharedSession()
            postGCMRegisterationIdRequest.HTTPMethod = "PUT"
            let data = registrationToken.dataUsingEncoding(NSUTF8StringEncoding)
            postGCMRegisterationIdRequest.HTTPBody = data
            postGCMRegisterationIdRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
            postGCMRegisterationIdRequest.addValue("application/json", forHTTPHeaderField: "Accept")
            NSLog("\(self.TAG): HttpPost: post GCM registration ID")
            let postGCMRegisterationIdTask = session.dataTaskWithRequest(postGCMRegisterationIdRequest, completionHandler: {data, response, error -> Void in
                do {
                    let _ = try NSJSONSerialization.JSONObjectWithData(data!, options: [])
                    NSLog("\(self.TAG): HttpPost: Successfuly posted GCM registration ID to server...")
                } catch {
                    // failure
                    NSLog("\(self.TAG): HttpPost: Error: \((error as NSError).localizedDescription)")
                }
            })
            postGCMRegisterationIdTask.resume()
        }
    }
    
    func onTokenRefresh() {
        // A rotation of the registration tokens is happening, so the app needs to request a new token.
        print("The GCM registration token needs to be refreshed.")
        GGLInstanceID.sharedInstance().tokenWithAuthorizedEntity(Config.GCM_SENDER_ID, scope: kGGLInstanceIDScopeGCM, options: registrationOptions, handler: registrationHandler)
    }
}
