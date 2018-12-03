import UIKit

class InvitationTableViewCell: UITableViewCell {
    
    
    @IBOutlet weak var changeIcon: UIImageView!
    @IBOutlet weak var labelInvitationName: UILabel!
    @IBOutlet weak var labelFinalTime: UILabel!
    @IBOutlet weak var labelFinalLocation: UILabel!
    @IBOutlet weak var timeIcon: UIImageView!

    @IBOutlet weak var locationIcon: UIImageView!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
