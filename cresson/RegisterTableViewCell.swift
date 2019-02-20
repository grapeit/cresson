import UIKit

class RegisterTableViewCell: UITableViewCell {

  @IBOutlet weak var label: UILabel!
  var registerId = 0

  override func awakeFromNib() {
      super.awakeFromNib()
      // Initialization code
  }

  override func setSelected(_ selected: Bool, animated: Bool) {
      super.setSelected(selected, animated: animated)
      // Configure the view for the selected state
  }

  func setRegister(_ register: BikeData.Register) {
    registerId = register.id
    label.text = register.label()
  }
}
