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
}
