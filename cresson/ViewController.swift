import UIKit

class ViewController: UIViewController {

  var btConnection: BtConnection!

  override func viewDidLoad() {
    super.viewDidLoad()
    btConnection = BtConnection(self)
  }
}

extension ViewController: BtConnectionDelegate {
  func status(_ status: String) {
    print(status)
  }

  func data(_ data: BikeData) {
    print(String(data: try! JSONEncoder().encode(data), encoding: .utf8)!)
  }
}
