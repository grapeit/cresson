import UIKit

class ViewController: UIViewController {

  @IBOutlet weak var dataView: UITableView!
  @IBOutlet weak var statusLabel: UILabel!

  var btConnection: BtConnection!
  var bikeData: BikeData?
  var viewCells = [UITableViewCell]()
  var registerRows = [Int: Int]()

  override func viewDidLoad() {
    super.viewDidLoad()
    btConnection = BtConnection(self)
    dataView.delegate = self
    dataView.dataSource = self
    statusLabel.text = "Hello"
  }

  func cellFor(register: Int) -> UITableViewCell {
    if let r = registerRows[register] {
      return viewCells[r]
    }
    let c = UITableViewCell()
    c.backgroundColor = dataView.backgroundColor
    registerRows[register] = viewCells.count
    viewCells.append(c)
    return c
  }

  func updateCells() {
    guard let bikeData = bikeData else {
      return
    }
    for r in bikeData.registers {
      cellFor(register: r.id).textLabel?.text = r.label()
    }
  }
}

extension ViewController: BtConnectionDelegate {
  func status(_ status: String) {
    statusLabel.text = status
    print(status)
  }

  func data(_ data: BikeData) {
    print(String(data: try! JSONEncoder().encode(data), encoding: .utf8)!)
    let reload = bikeData != nil ? bikeData?.registers.count != data.registers.count : true
    bikeData = data
    updateCells()
    if reload {
      dataView.reloadData()
    }
    statusLabel.text = bikeData?.statusLabel()
  }
}

extension ViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return viewCells.count
  }
}

extension ViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    return viewCells[indexPath.row]
  }
}
