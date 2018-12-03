import UIKit


class ChangeIconVisible:NSObject{
    
    func checkChangeIconVisible(inviteid: String){
        if (InvitationDetailsViewController().isViewLoaded() && InvitationDetailsViewController().view.window != nil){
            return
        }
        let invitations = InvitationDataManager().getAllInvitations()
        for invitation in invitations{
            
            if (invitation.id == inviteid){
                invitation.changeIconVisible = true
                let updateChangeIconVisibleSQL = "UPDATE INVITATION SET changeIconVisible = 1 WHERE id='\(inviteid)'"
                let resultChangeIcon = databaseOpenHandler.socialdiningDB!.executeUpdate(updateChangeIconVisibleSQL, withArgumentsInArray: nil)
                if !resultChangeIcon {
                    NSLog(" DB UPDATE: ChangeIconVisible: Error: \(databaseOpenHandler.socialdiningDB!.lastErrorMessage())")
                } else {
                    NSLog(" DB UPDATE: ChangeIconVisible: for Invitation: \(invitation.invitationName) was successfuly added to the database.")
                }
                
            }
        }
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            //NSNotificationCenter.defaultCenter().postNotificationName("redrawInvitationDetailsScreen", object: nil)
            NSNotificationCenter.defaultCenter().postNotificationName("redrawInvitationListID", object: nil)
            //NSNotificationCenter.defaultCenter().postNotificationName("redrawInvitationDetailsScreen", object: nil)
        })
    }
    
    
}
