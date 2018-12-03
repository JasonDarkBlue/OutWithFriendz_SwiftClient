import UIKit

class GoogleReviewsViewController: UIViewController {
    @IBOutlet weak var webView: UIWebView!
    var placeId: String = String()
    var kGOOGLE_API_KEY="AIzaSyApelf7SN-tOxAUa8x6furRtxzR_XcOtes"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /*Retrieve location URL from Google Places API using sent place ID*/
        let placeDetailsBaseURL = "https://maps.googleapis.com/maps/api/place/details/json?"
        let placeDetailsURL = placeDetailsBaseURL+"placeid=\(placeId)&key=\(kGOOGLE_API_KEY)"
        let request = NSMutableURLRequest(URL: NSURL(string: placeDetailsURL)!)
        httpGet(request){
            (data, error) -> Void in
            if error != nil{
                print(error)
            } else{
                //parse json
                self.getURLFromJson(data as String)
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
    
    func getURLFromJson(placeDataString: NSString){
        /*Get url field from JSON*/
        let placeData = placeDataString.dataUsingEncoding(NSUTF8StringEncoding)
        let json = JSON(data: placeData!)
        if let resultDictionary = json["result"].dictionary{
            if let urlPath = resultDictionary["url"]?.string{
                loadAddressURL(urlPath)
            }
        }
    }
    
    func loadAddressURL(urlPath: String){
        /*display the url in webview*/
        let requestURL = NSURL(string: urlPath)
        let request = NSURLRequest(URL: requestURL!)
        webView.loadRequest(request)
    }
}
