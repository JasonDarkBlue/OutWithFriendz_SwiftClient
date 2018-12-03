import UIKit

class DateVotingTableViewCell: UITableViewCell {
    
    var checked: Bool = false
    
    @IBOutlet weak var labelDate: UILabel!
    @IBOutlet weak var checkBoxButtonDate: UIButton!
    @IBOutlet weak var labelDateCount: UILabel!
    @IBOutlet weak var labelFinal: UILabel!
    
    //images
    let checkedImage = UIImage(named:"heart-red-icon")
    let uncheckedImage = UIImage(named:"heart-gray-icon")
    

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        checkBoxButtonDate.setImage(uncheckedImage, forState: UIControlState.Normal)
        let finalString = "final!"
//        let myMutableString = NSMutableAttributedString(string: finalString, attributes: [NSFontAttributeName:UIFont(name: "Chalkduster", size: 14.0)!])
//        labelFinal.attributedText = myMutableString
        
        labelFinal.text = finalString
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    

    @IBAction func checkBox(sender: UIButton) {
        
        
        NSLog("... Date checkBox0 ...")
        if (!checked) {
            checked = true
            NSLog("... Date checkBox1 ...")
            checkBoxButtonDate.setImage(checkedImage, forState: UIControlState.Normal)
            
        }
            
        else if (checked) {
            checked = false
            NSLog("... Date checkBox2 ...")
            checkBoxButtonDate.setImage(uncheckedImage, forState: UIControlState.Normal)
            
        }
        
        
    }
    
    func toggleHeart(){
        NSLog("... Date toggleHeart ...")
        if (!checked) {
            checked = true
            NSLog("... Date toggleHeart1 ...")
            checkBoxButtonDate.setImage(checkedImage, forState: UIControlState.Normal)
            
        }
            
        else if (checked) {
            checked = false
            NSLog("... Date toggleHeart2 ...")
            checkBoxButtonDate.setImage(uncheckedImage, forState: UIControlState.Normal)
            
        }
    }

    
    func checkVotingBox(){
        checked = true
        checkBoxButtonDate.setImage(checkedImage, forState: UIControlState.Normal)
    }
    
    func unCheckVotingBox(){
        checked = false
        checkBoxButtonDate.setImage(uncheckedImage, forState: UIControlState.Normal)
    }

}
