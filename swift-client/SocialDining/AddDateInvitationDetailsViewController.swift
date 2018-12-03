import UIKit

class AddDateInvitationDetailsViewController: UIViewController {

    @IBOutlet weak var datePicker: UIDatePicker!
    var newPossibleInvitationDate: PossibleInvitationDate = PossibleInvitationDate()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        newPossibleInvitationDate.eventDate = NSDate()
    }
    
    @IBAction func datePickerAction(sender: AnyObject) {
        newPossibleInvitationDate.eventDate = datePicker.date
    }
}
