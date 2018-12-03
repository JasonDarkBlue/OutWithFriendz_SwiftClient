import UIKit

class EditTitleViewController: UIViewController {
    
    var placeInvitation: Restaurant?
    var invitation: Invitation?
    @IBOutlet weak var address: UITextField!
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var titleInvitation: UITextField!
    
    @IBOutlet weak var addressLabel: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let place = placeInvitation{
            address.text = place.formattedAddress!
            titleInvitation.text = place.name!
            titleLabel.textColor = UIColor(hue: 0.6917, saturation: 1, brightness: 0.75, alpha: 1.0)
            addressLabel.textColor = UIColor(hue: 0.6917, saturation: 1, brightness: 0.75, alpha: 1.0)
            
        }
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
        
        if identifier == "saveEditPlaceUnwindSegue"{
            let inviteName = titleInvitation.text
            if !isWhiteSpace(inviteName!) && inviteName!.characters.count > 2 {
                return true
            }else{
                popupMessageHandler.displayInfoMessage("Title Error!", content: "You seem to have entered a meaningless invitation title.", viewController: self)
            }
        }
        
        if identifier == "cancelEditPlaceUnwindSegue"{
            return true
        }
        
        return false
    }
    
    func isWhiteSpace(text: String) -> Bool {
        let trimmed = text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        return trimmed.isEmpty
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
