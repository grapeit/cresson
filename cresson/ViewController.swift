import UIKit

let registerSaveInterval = 20.0


class ViewController: UIViewController {

  @IBOutlet weak var dataView: UITableView!
  @IBOutlet weak var statusLabel: UILabel!

  var btConnection: BtConnection!
  let bikeData = BikeData()
  var saveTimer: Timer!
  var connected = false


  override func viewDidLoad() {
    super.viewDidLoad()
    btConnection = BtConnection(self)
    bikeData.btConnection = btConnection
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
    if connected != btConnection.connected {
      connected = btConnection.connected
      dataView.reloadData()
      if connected {
        bikeData.sendMap()
      }
    }
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
          c.setRegister(r, connected: connected)
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
    if id == .map {
      return UISwipeActionsConfiguration(actions: [switchMap(at: indexPath)])
    }
    return UISwipeActionsConfiguration(actions: [])
  }

  private func reset(register: BikeData.RegisterId, at indexPath: IndexPath) -> UIContextualAction {
    let action = UIContextualAction(style: .normal, title: "Reset") { (action, view, completion) in
      self.bikeData.resetRegister(register)
      self.dataView.reloadRows(at: [indexPath], with: .none)
      completion(true)
    }
    action.backgroundColor = .red
    return action
  }

  private func switchMap(at indexPath: IndexPath) -> UIContextualAction {
    let current = bikeData.getRegister(.map)?.value ?? 0
    let next = current == 1 ? 2 : 1
    return UIContextualAction(style: .normal, title: "\(next)") { (action, view, completion) in
      self.bikeData.setRegister(BikeData.Register(id: .map, value: next, timestamp: Date().timeIntervalSinceReferenceDate))
      self.dataView.reloadRows(at: [indexPath], with: .none)
      completion(true)
    }
  }
}

extension ViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = dataView.dequeueReusableCell(withIdentifier: "RegisterTableViewCell", for: indexPath)
    if let cell = cell as? RegisterTableViewCell {
      cell.setRegister(bikeData.registers[indexPath.row], connected: connected)
    }
    return cell
  }
}
