import UIKit

class ShareTableViewCell: UITableViewCell {
    
    @IBOutlet weak var shareImage: UIImageView!
    
    @IBOutlet weak var shareText: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
