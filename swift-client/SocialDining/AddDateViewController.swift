import UIKit

class AddDateViewController: UIViewController {

    var newPossibleInvitationDate: PossibleInvitationDate = PossibleInvitationDate()
    
    @IBOutlet weak var datePicker: UIDatePicker!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        newPossibleInvitationDate.eventDate = NSDate()
    }

    @IBAction func datePickerAction(sender: AnyObject) {
            newPossibleInvitationDate.eventDate = datePicker.date
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "SaveDate" {
            print("addDate-prepareForSegue", terminator: "")
        }
    }
    
}