//Singelton pattern
var restaurantDataManager: RestaurantDataManager = RestaurantDataManager()

import UIKit
import MapKit

class RestaurantDataManager: NSObject {
    
    
    let TAG = "RestaurantDataManager"

    override init() {
        
    }
    
    /*A method that posts a new Place to an Invitation*/
    func postPlaceToInvitationOnServer(newPlace: Restaurant, invitationID: String){
        NSLog("\(self.TAG): Start: Post place: \(newPlace.name) to invite: \(invitationID)")
        let newPlaceParameters:  NSMutableDictionary = NSMutableDictionary()
        newPlaceParameters.setObject(newPlace.name!, forKey: "name")
        newPlaceParameters.setObject(newPlace.placeId!, forKey: "place_id")
        newPlaceParameters.setObject(newPlace.formattedAddress!, forKey: "vicinity")
        newPlaceParameters.setObject(newPlace.desc!, forKey: "description")
        newPlaceParameters.setObject(newPlace.userId!, forKey: "userId")
        /*First, we need to create the new Place object on the server side*/
        let createNewPlaceRequest = NSMutableURLRequest(URL: NSURL(string: Config.SERVER_URL+"/places")!)
        let session = NSURLSession.sharedSession()
        createNewPlaceRequest.HTTPMethod = "POST"
        var err: NSError?
        do {
            createNewPlaceRequest.HTTPBody = try NSJSONSerialization.dataWithJSONObject(newPlaceParameters, options: [])
        } catch let error as NSError {
            err = error
            print("\(self.TAG): \(err?.localizedDescription)")
            createNewPlaceRequest.HTTPBody = nil
        }
        createNewPlaceRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        createNewPlaceRequest.addValue("application/json", forHTTPHeaderField: "Accept")
        NSLog("\(self.TAG): HttpPost: Post place1:")
        let createNewPlaceTask = session.dataTaskWithRequest(createNewPlaceRequest, completionHandler: {data, response, error -> Void in
            /*strData containts the body of the response*/
            /*Get new place Id frpm returned data*/
            let strData = NSString(data: data!, encoding: NSUTF8StringEncoding)
            let newPlaceId = strData!
            
            NSLog("\(self.TAG): HttpPost: Post place1: Got id: \(newPlaceId)")
            
            /*Use the new returned Id for the new Place to post the new Object to the Invitation*/
            newPlaceParameters.setObject(newPlaceId, forKey: "id")
            let postPlaceToInvitationRequest = NSMutableURLRequest(URL: NSURL(string: Config.SERVER_URL+"/invitations/"+invitationID+"/Places")!)
            postPlaceToInvitationRequest.HTTPMethod = "POST"
            var err: NSError?
            do {
                postPlaceToInvitationRequest.HTTPBody = try NSJSONSerialization.dataWithJSONObject(newPlaceParameters, options: [])
            } catch let error as NSError {
                err = error
                NSLog("\(self.TAG): HttpPost: Post place1: Error: \(err?.localizedDescription)")
                postPlaceToInvitationRequest.HTTPBody = nil
            } catch {
                fatalError()
            }
            postPlaceToInvitationRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
            postPlaceToInvitationRequest.addValue("application/json", forHTTPHeaderField: "Accept")
            NSLog("\(self.TAG): HttpPost: Post place2")
            let postPlaceToInvitationTask = session.dataTaskWithRequest(postPlaceToInvitationRequest, completionHandler: {data, response, error -> Void in
                do {
                    let _ = try NSJSONSerialization.JSONObjectWithData(data!, options: [])
                    NSLog("\(self.TAG): HttpPost: Post place2: Successfuly posted Final Place to server...")
                } catch {
                    // failure
                    NSLog("\(self.TAG): HttpPost: Post place2: \((error as NSError).localizedDescription)")
                }
            })
            postPlaceToInvitationTask.resume()
        })
        createNewPlaceTask.resume()
    }
    
    /*A method that deletes an existing Place from an Invitation*/
    func deletePlaceFromInvitationOnServer(place: Restaurant, invitationID: String){
        NSLog("\(self.TAG): Start: Delete place: \(place.id!) from invite: \(invitationID)")
        //To-do: the delete takes NO PARAMETER
        //It is only a call to "/possibleInvitationDateVotes/{voteid}"
        
        let placeId = place.id!
        let deletePlaceURL = Config.SERVER_URL+"/invitations/\(invitationID)/deletePlace/\(placeId)"
        let request = NSMutableURLRequest(URL: NSURL(string: deletePlaceURL)!)
        request.HTTPMethod = "DELETE"
        NSLog("\(self.TAG): HttpDelete: Delete place:")
        httpGet(request){
            (data, error) -> Void in
            if error != nil{
                NSLog("\(self.TAG): HttpDelete: Delete place: error")
                print(error)
            } else{
                NSLog("\(self.TAG): HttpDelete: Delete place: Successfully posted delete Place to server...")
            }
        }
    }
    
    /*A method that gets all Places for an invitation*/
    func getListOfPlacesForInvitationFromLocalDB(inviteid: NSString)->[Restaurant]{
        
        var places: [Restaurant] = [Restaurant]()
        if databaseOpenHandler.open(){

            let queryPlacesSQL = "SELECT id, name, inviteid, place_id, vicinity, description, userId FROM PLACE WHERE inviteid='\(inviteid)'"

            let placesResults:FMResultSet? = databaseOpenHandler.socialdiningDB!.executeQuery(queryPlacesSQL, withArgumentsInArray: nil)
            while placesResults?.next() == true {
                let place: Restaurant = Restaurant()
                place.id = placesResults!.stringForColumn("id")
                place.name = placesResults!.stringForColumn("name")
                place.placeId = placesResults!.stringForColumn("place_id")

                place.formattedAddress = placesResults!.stringForColumn("vicinity")
                place.desc = placesResults!.stringForColumn("description")
                place.userId = placesResults!.stringForColumn("userId")

                places.append(place)
            }
        }
        return places
    }
    
    func getRestaurantsInCanvas(southWestCorner: CLLocationCoordinate2D, northEastCorner: CLLocationCoordinate2D) -> [Restaurant]{
        var restaurants = [Restaurant]()
        
        //construct and call URL to retreive restaurants with the current rectangle
        let serverURL = "http://128.138.232.94:8080/SocialDining-server"
        let restsURL = serverURL+"/restaurants/withinBox?lowerLeftLon=\(southWestCorner.longitude)&lowerLeftLat=\(southWestCorner.latitude)&upperRightLon=\(northEastCorner.longitude)&upperRightLat=\(northEastCorner.latitude)&categoryName=All"
        
        let request = NSMutableURLRequest(URL: NSURL(string: restsURL)!)
        NSLog("\(self.TAG): HttpGet: get rests")
        httpGet(request){
            (data, error) -> Void in
            if error != nil{
                NSLog("\(self.TAG): HttpGet: get rests: error)")
                print(error)
            } else{
                //parse returned data
                restaurants = self.convertJsonToArray(data as String)
                NSLog("\(self.TAG): HttpGet: get rests: getRestaurantsInCanvas: \(restaurants.count)")
            }
        }
        
        return restaurants
    }
    
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
        var restuarants = [Restaurant]()
        
        let restaurantData = restaurantDataString.dataUsingEncoding(NSUTF8StringEncoding)
        let jsonArray = JSON(data: restaurantData!).arrayValue
        
        for restJson in jsonArray{
            let restaurant = Restaurant()
            //name
            if let restName = restJson["name"].string{
                restaurant.name = restName
            }
            //address
            if let streetAddress = restJson["location"]["streetAddress"].string{
                restaurant.subtitle = streetAddress
            }
            //location CLLocationCoordinate2D -> (latitude - CLLocationDegrees, longitude - CLLocationDegrees)
            if let _ = restJson["location"]["lat"].double{
                if let _ = restJson["location"]["lon"].double{
                    let lat: CLLocationDegrees = 40.012630894662145
                    let long: CLLocationDegrees = -105.26061518892618
                    let _: CLLocationCoordinate2D = CLLocationCoordinate2DMake(lat, long)
                }
            }
            restuarants.append(restaurant)
        }
        print("convertJsonToArray: \(restuarants.count)")
        return restuarants
    }
    
    func postFinalPlaceToInvitationOnServer(finalPlace: Restaurant, invitationID: String){
        NSLog("\(self.TAG): Start: post final Place")
        let finalPlaceParameters:  NSMutableDictionary = NSMutableDictionary()
        finalPlaceParameters.setObject(finalPlace.id!, forKey: "id")
        finalPlaceParameters.setObject(finalPlace.placeId!, forKey: "place_id")
        finalPlaceParameters.setObject(finalPlace.name!, forKey: "name")
        let postFinalPlaceToInvitationRequest = NSMutableURLRequest(URL: NSURL(string: Config.SERVER_URL+"/invitations/"+invitationID+"/eventPlace")!)
        var err: NSError?
        let session = NSURLSession.sharedSession()
        postFinalPlaceToInvitationRequest.HTTPMethod = "PUT"
        do {
            postFinalPlaceToInvitationRequest.HTTPBody = try NSJSONSerialization.dataWithJSONObject(finalPlaceParameters, options: [])
        } catch let error as NSError {
            err = error
            NSLog("\(self.TAG): HttpPUT: Error: \(err?.localizedDescription)")
            postFinalPlaceToInvitationRequest.HTTPBody = nil
        }
        postFinalPlaceToInvitationRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        postFinalPlaceToInvitationRequest.addValue("application/json", forHTTPHeaderField: "Accept")
        NSLog("\(self.TAG): HttpPUT: post final Place")
        let postFinalPlaceToInvitationTask = session.dataTaskWithRequest(postFinalPlaceToInvitationRequest, completionHandler: {data, response, error -> Void in
            do {
                let _ = try NSJSONSerialization.JSONObjectWithData(data!, options: [])
                 NSLog("\(self.TAG): HttpPUT: Successfuly posted Final Place to server...")
            } catch {
                // failure
                 NSLog("\(self.TAG): HttpPUT: \((error as NSError).localizedDescription)")
            }
        })
        postFinalPlaceToInvitationTask.resume()
    }
    
    func updatePlaceToInvitationOnServer(updatePlace: Restaurant, invitationID: String){
        NSLog("\(self.TAG): Start: update Place Title")
        let updatePlaceParameters:  NSMutableDictionary = NSMutableDictionary()
        updatePlaceParameters.setObject(updatePlace.id!, forKey: "id")
        updatePlaceParameters.setObject(updatePlace.placeId!, forKey: "place_id")
        updatePlaceParameters.setObject(updatePlace.name!, forKey: "name")
        updatePlaceParameters.setValue(updatePlace.formattedAddress!, forKey: "vicinity")
        let updatePlaceURL = Config.SERVER_URL+"/invitations" + "/\(invitationID)/\(updatePlace.placeId!)/updatePlace"
        let updatePlaceRequest = NSMutableURLRequest(URL: NSURL(string: updatePlaceURL)!)
        var err: NSError?
        let session = NSURLSession.sharedSession()
        updatePlaceRequest.HTTPMethod = "PUT"
        do {
            updatePlaceRequest.HTTPBody = try NSJSONSerialization.dataWithJSONObject(updatePlaceParameters, options: [])
        } catch let error as NSError {
            err = error
            NSLog("\(self.TAG): HttpPUT: Error: \(err?.localizedDescription)")
            updatePlaceRequest.HTTPBody = nil
        }
        updatePlaceRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        updatePlaceRequest.addValue("application/json", forHTTPHeaderField: "Accept")
        NSLog("\(self.TAG): HttpPUT: update Place Title")
        let updatePlaceTask = session.dataTaskWithRequest(updatePlaceRequest, completionHandler: {data, response, error -> Void in
            do {
                let _ = try NSJSONSerialization.JSONObjectWithData(data!, options: [])
                NSLog("\(self.TAG): HttpPUT: Successfuly update Place Title to server...")
            } catch {
                // failure
                NSLog("\(self.TAG): HttpPUT: \((error as NSError).localizedDescription)")
            }
        })
        updatePlaceTask.resume()
    }
    
    func debugRequest(request: NSMutableURLRequest){
        NSLog("Debug information for URL request: ")
        print(request.allHTTPHeaderFields)
        let body = NSString(data: request.HTTPBody!, encoding: NSUTF8StringEncoding)!
        print(body)
    }

}
