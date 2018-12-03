import UIKit

class PlaceVotingTableViewCell: UITableViewCell {

    
    var checked: Bool = false
    
    @IBOutlet weak var labelPlaceName: UILabel!
    @IBOutlet weak var checkBoxButtonPlace: UIButton!
    @IBOutlet weak var labelFinal: UILabel!
    @IBOutlet weak var labelPlaceCount: UILabel!
    
    //images
    let checkedImage = UIImage(named:"heart-red-icon")
    let uncheckedImage = UIImage(named:"heart-gray-icon")
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
        // Initialization code
        
        checkBoxButtonPlace.setImage(uncheckedImage, forState: UIControlState.Normal)
        checkBoxButtonPlace.userInteractionEnabled = true
        let finalString = "final!"
 //       let myMutableString = NSMutableAttributedString(string: finalString, attributes: [NSFontAttributeName:UIFont(name: "Chalkduster", size: 14.0)!])
//        labelFinal.attributedText = myMutableString
        
        
        labelFinal.text = finalString
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }


    @IBAction func checkBox(sender: UIButton) {
        if (!checked) {
            checked = true
            checkBoxButtonPlace.setImage(checkedImage, forState: UIControlState.Normal)
            
        }
            
        else if (checked) {
            checked = false
            checkBoxButtonPlace.setImage(uncheckedImage, forState: UIControlState.Normal)
            
        }
    }
    
    func toggleHeart(){
        if (!checked) {
            checked = true
            checkBoxButtonPlace.setImage(checkedImage, forState: UIControlState.Normal)
            
        }
            
        else if (checked) {
            checked = false
            checkBoxButtonPlace.setImage(uncheckedImage, forState: UIControlState.Normal)
            
        }
    }
    
    
    func checkVotingBox(){
        checked = true
        checkBoxButtonPlace.setImage(checkedImage, forState: UIControlState.Normal)
    }
    
    func unCheckVotingBox(){
        checked = false
        checkBoxButtonPlace.setImage(uncheckedImage, forState: UIControlState.Normal)
    }
}
