import UIKit

class RegisterTableViewCell: UITableViewCell {

  @IBOutlet weak var label: UILabel!
  var registerId: BikeData.RegisterId?

  override func awakeFromNib() {
      super.awakeFromNib()
      // Initialization code
  }

  override func setSelected(_ selected: Bool, animated: Bool) {
      super.setSelected(selected, animated: animated)
      // Configure the view for the selected state
  }

  func setRegister(_ register: BikeData.Register, connected: Bool) {
    registerId = register.id
    label.text = register.label()
    label.textColor = (!connected && register.id.isLive()) ? .lightGray : .black
  }
}
