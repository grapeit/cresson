import UIKit

class ViewController: UIViewController {

  var btConnection: BtConnection!

  @IBOutlet weak var statusLabel: UILabel!

  override func viewDidLoad() {
    super.viewDidLoad()
    btConnection = BtConnection(self)
    statusLabel.text = "Hello"
  }
}

extension ViewController: BtConnectionDelegate {
  func status(_ status: String) {
    statusLabel.text = status
    print(status)
  }

  func data(_ data: BikeData) {
    print(String(data: try! JSONEncoder().encode(data), encoding: .utf8)!)
  }
}
