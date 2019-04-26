import UIKit

let registerSaveInterval = 20.0


class ViewController: UIViewController {

  @IBOutlet weak var dataView: UITableView!
  @IBOutlet weak var statusLabel: UILabel!

  var btConnection: BtConnection!
  let bikeData = BikeData()
  var saveTimer: Timer!


  override func viewDidLoad() {
    super.viewDidLoad()
    btConnection = BtConnection(self)
    dataView.register(UINib(nibName: "RegisterTableViewCell", bundle: nil), forCellReuseIdentifier: "RegisterTableViewCell")
    dataView.delegate = self
    dataView.dataSource = self
    statusLabel.text = ""
    saveTimer = Timer.scheduledTimer(withTimeInterval: registerSaveInterval, repeats: true) { _ in self.bikeData.save() }
    NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: nil) { _ in self.bikeData.save() }
    NotificationCenter.default.addObserver(forName: UIApplication.willTerminateNotification, object: nil, queue: nil) { _ in self.bikeData.save() }
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
        if let c = c as? RegisterTableViewCell, let id = c.registerId, let r = bikeData.getRegister(id) {
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

  func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
    let id = bikeData.registers[indexPath.row].id
    if id == .trip {
      return UISwipeActionsConfiguration(actions: [reset(register: id, at: indexPath)])
    }
    return UISwipeActionsConfiguration(actions: [])
  }

  private func reset(register: BikeData.RegisterId, at indexPath: IndexPath) -> UIContextualAction {
    let action = UIContextualAction(style: .normal, title: "Reset") { (action, view, completion) in
      self.bikeData.resetRegister(register)
      self.bikeData.save()
      self.dataView.reloadRows(at: [indexPath], with: .none)
      completion(true)
    }
    action.backgroundColor = .red
    return action
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
