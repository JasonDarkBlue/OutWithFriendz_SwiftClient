import UIKit
import MapKit
import ObjectMapper
import CoreLocation

class AddPlaceInvitationDetailsViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate{
    
    let TAG = "AddPlaceInvitationDetailsViewController"
    
    
    
    @IBOutlet weak var theMapView: MKMapView!
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var searchHereBtn: UIButton!
    @IBOutlet weak var poweredByGoogle: UIImageView!
    
    var locationManager: CLLocationManager = CLLocationManager()
    var kGOOGLE_API_KEY="AIzaSyApelf7SN-tOxAUa8x6furRtxzR_XcOtes"
    var newRest: Restaurant = Restaurant()
    var selectedRestPlaceId: String = String()
    
    var lastPlaceSearchQuery: NSString = NSString()
    var lastPlaceSearchResultsArray: [Restaurant] = [Restaurant]()
    
    /*Variables holding user information from NSUserDefaults*/
    var userDic: NSObject?
    var hostName: String?
    var hostId: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /*Adding location tracking button*/
        let bbi = MKUserTrackingBarButtonItem(mapView: theMapView)
        self.navigationItem.rightBarButtonItem = bbi

        /*Initializing location manager for user location info*/
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.requestWhenInUseAuthorization()
        self.locationManager.startUpdatingLocation()
        /*Adding rounded edges to search here button*/
        searchHereBtn.layer.cornerRadius = 5
        searchTextField.text = lastPlaceSearchQuery as String
        
        NSLog("Number of cached rests: \(lastPlaceSearchResultsArray.count)")
        
        /*Get authenticated user information from NSUserDefaults*/
        userDic = userDataManager.getAuthenticatedUser()
        hostName = userDic!.valueForKey("name") as? String
        hostId = userDic!.valueForKey("id") as? String
        
        /*Adding magnifying glass icon to search text field*/
        let magnifyingGlass: UILabel = UILabel()
        let utf8 : [UInt8] = [0xF0, 0x9F, 0x94, 0x8D]
        let str = NSString(bytes: utf8, length: utf8.count, encoding: NSUTF8StringEncoding)
        magnifyingGlass.text = str as? String
        magnifyingGlass.sizeToFit()
        magnifyingGlass.userInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: "searchHereClicked:")
        magnifyingGlass.addGestureRecognizer(tapGesture)
        searchTextField.rightView = magnifyingGlass
        searchTextField.rightViewMode = UITextFieldViewMode.Always
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /*Location update delegates*/
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        CLGeocoder().reverseGeocodeLocation(manager.location!, completionHandler: { (placemarks, error) -> Void in
            if (error != nil){
                return
            }
            if let pm = placemarks?.first {
                self.displayLocationInfo(pm)
            }else{
                NSLog("\(self.TAG): Error with data!")
            }
        })
    }
    
    func displayLocationInfo(placemark: CLPlacemark){
        self.locationManager.startUpdatingLocation()
        /*Default map to user location*/
        let currentLocation = placemark.location
        let currentLocationCoordinates = currentLocation!.coordinate
        /*These values represent how much we will zoom out*/
        let latDelta: CLLocationDegrees = 0.05
        let longDelta: CLLocationDegrees = 0.05
        /*Start zooming*/
        /*If there is no cache results, zoom to user location*/
        if(lastPlaceSearchResultsArray.isEmpty){
            let theSpan: MKCoordinateSpan = MKCoordinateSpanMake(latDelta, longDelta)
            let theRegion: MKCoordinateRegion = MKCoordinateRegionMake(currentLocationCoordinates, theSpan)
            self.theMapView.setRegion(theRegion, animated: true)
        }else{//else, zoom to the cache results
            theMapView.showAnnotations(lastPlaceSearchResultsArray, animated: true)
            searchHereBtn.hidden = true
        }
        self.theMapView.showsUserLocation = true
        self.locationManager.stopUpdatingLocation()
        
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
         NSLog("\(self.TAG): Error: "+error.localizedDescription)
    }
    
    /*MapView delegates*/
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation{
            //return nil so map view draws "blue dot" for standard user location
            return nil
        }
        
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView
        if pinView == nil{
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView?.canShowCallout = true
            pinView?.animatesDrop = false
            pinView?.pinColor = .Red
            pinView?.rightCalloutAccessoryView = UIButton(type: .ContactAdd)
        }else{
            pinView?.annotation = annotation
        }
        
        return pinView
    }
    
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        _ = searchTextField.text
        /*Only display search here button when there is text in the search textfield*/
        /*and the user is the one who dragged the map*/
        if(searchTextField.text==""){
            searchHereBtn.hidden = true
        }else{
            if(isItUserChange()==true){
                searchHereBtn.hidden = false
            }
        }
    }
    
    /*A method that checks system gestures to identify if the map was dragged manually (not programmatically)*/
    func isItUserChange()->Bool{
        
        let view = self.theMapView.subviews[0] 
        
        if let gestureReconizers = view.gestureRecognizers{
            for recognizer in gestureReconizers{
                if(recognizer.state == UIGestureRecognizerState.Began || recognizer.state == UIGestureRecognizerState.Ended){
                    return true
                }
            }
        }
        
        return false
    }
    
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if control == view.rightCalloutAccessoryView {
            newRest = view.annotation as! Restaurant
            newRest.userId = hostId!
            self.performSegueWithIdentifier("savePlaceInvitationDetailsScreenSegue", sender: self)
        }
    }
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        let tapGesture: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "calloutTapped:")
        view.addGestureRecognizer(tapGesture)
    }
    
    func calloutTapped(sender:UIGestureRecognizer){
        let view = sender.view as! MKAnnotationView
        let selectedRest = view.annotation as! Restaurant
        selectedRestPlaceId = selectedRest.placeId!
        self.performSegueWithIdentifier("showGoogleReviewSegue2", sender: self)
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool{
        
        textField.resignFirstResponder();//the first responder is the keyboard and this cause it to go away
        if !isWhiteSpace(searchTextField.text!) && (searchTextField.text!).characters.count > 2{
            displayNewAnnotationsOnMap(searchTextField.text!)
        }else{
            popupMessageHandler.displayInfoMessage("Cannot Perform Search", content: "You seem to have entered a meaningless search term.", viewController: self)
        }
        return true
    }
    
    @IBAction func searchHereClicked(sender: AnyObject) {
        if !isWhiteSpace(searchTextField.text!) && searchTextField.text?.characters.count > 2{
            searchTextField.resignFirstResponder()
            displayNewAnnotationsOnMap(searchTextField.text!)
        }else{
            popupMessageHandler.displayInfoMessage("Cannot Perform Search", content: "You seem to have entered a meaningless search term.", viewController: self)
        }
    }
    
    func displayNewAnnotationsOnMap(searchString: String){
         NSLog("\(self.TAG): searching for \(searchString)")
        /*replace spaces in search string with + for URL use*/
        var searchTokenized: String = String()
        var searchStringTokensArr = searchString.characters.split {$0 == " "}.map { String($0) }
        if searchStringTokensArr.count>1 {
            for stringToken in searchStringTokensArr{
                searchTokenized+=stringToken+"+"
            }
        } else{
            searchTokenized = searchStringTokensArr[0]
        }
        var restaurants = [Restaurant]()
        let region = theMapView.region
        let center = region.center
        var southWestCorner = CLLocationCoordinate2D()
        var northEastCorner = CLLocationCoordinate2D()
        southWestCorner.latitude  = center.latitude  - (region.span.latitudeDelta  / 2.0);
        southWestCorner.longitude = center.longitude - (region.span.longitudeDelta / 2.0);
        northEastCorner.latitude  = center.latitude  + (region.span.latitudeDelta  / 2.0);
        northEastCorner.longitude = center.longitude + (region.span.longitudeDelta / 2.0);
        
        //construct and call URL to retreive locations from Google based on center of map
        let googleBaseURL = "https://maps.googleapis.com/maps/api/place/search/json?"
        let restsURL = googleBaseURL+"location=\(center.latitude),\(center.longitude)&keyword=\(searchTokenized)&radius=2000&sensor=true&key=\(kGOOGLE_API_KEY)"
        let request = NSMutableURLRequest(URL: NSURL(string: restsURL)!)
        httpGet(request){
            (data, error) -> Void in
            if error != nil{
                print(error, terminator: "")
            } else{
                //parse returned data and display on map
                restaurants = self.convertJsonToArray(data as String)
                if(restaurants.count>0){
                    dispatch_async(dispatch_get_main_queue()){
                        self.theMapView.removeAnnotations(self.theMapView.annotations)
                        self.theMapView.showAnnotations(restaurants, animated: true)
                        self.lastPlaceSearchResultsArray = restaurants
                    }
                }else{
                    popupMessageHandler.displayInfoMessage("Info", content: "Sorry, your search did not return any results.", viewController: self)
                }
            }
        }
        searchHereBtn.hidden = true
    }
    
    /*Delegates to handle segues*/
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showGoogleReviewSegue2" {
            /*Send Place_Id*/
            let googleReviewsViewController = segue.destinationViewController as! GoogleReviewsViewController
            googleReviewsViewController.placeId = selectedRestPlaceId
            
        }
    }
    
    /*Methods to handle Google Places API calls*/
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
    
    func convertJsonToArray(restaurantDataString: NSString) -> [Restaurant]{
        
        var restaurants = [Restaurant]()
        let restaurantData = restaurantDataString.dataUsingEncoding(NSUTF8StringEncoding)
        let json = JSON(data: restaurantData!)
        if let jsonArray = json["results"].array{
            for restJson in jsonArray{
                let restaurant = Mapper<Restaurant>().map(restJson.description)
                restaurants.append(restaurant!)
            }
        }
        NSLog("Google API returned: \(restaurants.count) locations!")
        return restaurants
    }

    func isWhiteSpace(text: String) -> Bool {
        let trimmed = text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        return trimmed.isEmpty
    }
}
