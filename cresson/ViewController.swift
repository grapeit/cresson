import UIKit

class ViewController: UIViewController {

  @IBOutlet weak var dataView: UITableView!
  @IBOutlet weak var statusLabel: UILabel!

  var btConnection: BtConnection!
  let bikeData = BikeData()

  override func viewDidLoad() {
    super.viewDidLoad()
    //bikeData.testData()
    btConnection = BtConnection(self)
    dataView.register(UINib(nibName: "RegisterTableViewCell", bundle: nil), forCellReuseIdentifier: "RegisterTableViewCell")
    dataView.delegate = self
    dataView.dataSource = self
    statusLabel.text = ""
  }
}

extension ViewController: BtConnectionDelegate {
  func status(_ status: String) {
    print(status)
    statusLabel.text = status
  }

  func update(_ data: BikeUpdate) {
    print(String(data: try! JSONEncoder().encode(data), encoding: .utf8)!)
    let reload = bikeData.update(data)
    if reload {
      dataView.reloadData()
    } else {
      for c in dataView.visibleCells {
        if let c = c as? RegisterTableViewCell, let r = bikeData.getRegister(c.registerId) {
          c.setRegister(r)
        }
      }
    }
    statusLabel.text = bikeData.status
  }
}

extension ViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return bikeData.registers.count
  }
}

extension ViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = dataView.dequeueReusableCell(withIdentifier: "RegisterTableViewCell", for: indexPath)
    if let cell = cell as? RegisterTableViewCell {
      cell.setRegister(bikeData.registers[indexPath.row])
    }
    return cell
  }
}
