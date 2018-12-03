var popupMessageHandler: PopupMessageHandler = PopupMessageHandler()

import UIKit

class PopupMessageHandler: NSObject {
    /*Helper method to dislay a message with (Ok, Cancel) buttons*/
    func displayMessage(title: String, content: String, viewController : UIViewController, okAction: ()->Void){
        let alertController = UIAlertController(title: title, message:content, preferredStyle: .Alert)
        let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .Cancel) { action -> Void in
            /*Cancel button does nothing*/
        }
        alertController.addAction(cancelAction)
        let confirmAction: UIAlertAction = UIAlertAction(title: "Ok", style: .Default) { action -> Void in
            okAction()
        }
        alertController.addAction(confirmAction)
        viewController.presentViewController(alertController, animated: true, completion: nil)
    }
    
    /*Helper method to dislay a message with (Cancel) button*/
    func displayInfoMessage(title: String, content: String, viewController: UIViewController){
        let alert = UIAlertController(title: title, message: content, preferredStyle: UIAlertControllerStyle.Alert)
        let okAction = UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil)
        alert.addAction(okAction)
        viewController.presentViewController(alert, animated: true, completion: nil)
    }
}
