var notificationHandler: NotificationHandler = NotificationHandler()

import UIKit

class NotificationHandler: NSObject {
    
    func fireNotification(alertBody: String, alertAction: String){
        let notification = UILocalNotification()
        notification.alertBody = alertBody
        notification.alertAction = alertAction
        /*Only fire notification and increment badge number if the is not in foreground*/
        let state = UIApplication.sharedApplication().applicationState
        if state == UIApplicationState.Inactive || state == UIApplicationState.Background{
            UIApplication.sharedApplication().presentLocalNotificationNow(notification)
            UIApplication.sharedApplication().applicationIconBadgeNumber+=1
        }
    }
}
