import UIKit

let registerSaveInterval = 20.0


class DashboardViewController: UIViewController {

  @IBOutlet weak var dataView: UITableView!
  @IBOutlet weak var statusLabel: UILabel!

  var btConnection = BtConnection()
  let bikeData = BikeData()
  var saveTimer: Timer!
  var connected = false


  override func viewDidLoad() {
    super.viewDidLoad()
    dataView.register(UINib(nibName: "RegisterTableViewCell", bundle: nil), forCellReuseIdentifier: "RegisterTableViewCell")
    dataView.delegate = self
    dataView.dataSource = self
    dataView.tableFooterView = UIView(frame: .zero)
    statusLabel.text = ""
    saveTimer = Timer.scheduledTimer(withTimeInterval: registerSaveInterval, repeats: true) { _ in self.bikeData.save() }
    NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: nil) { _ in self.bikeData.save() }
    NotificationCenter.default.addObserver(forName: UIApplication.willTerminateNotification, object: nil, queue: nil) { _ in self.bikeData.save() }
    btConnection.delegate = self
    btConnection.start()
    bikeData.btConnection = btConnection
  }
}

extension DashboardViewController: BtConnectionDelegate {
  func status(_ status: String) {
    print(status)
    if !btConnection.connected {
      connected = false
      dataView.reloadData()
    }
    statusLabel.text = status
  }

  func update(_ data: BikeUpdate) {
    print(String(data: try! JSONEncoder().encode(data), encoding: .utf8)!)
    bikeData.update(data)
    for c in dataView.visibleCells {
      if let c = c as? RegisterTableViewCell, let id = c.registerId, let r = bikeData.getRegister(id) {
        c.setRegister(r, connected: connected)
      }
    }
    if connected != bikeData.connected {
      connected = bikeData.connected
      dataView.reloadData()
    }
    statusLabel.text = bikeData.status
  }
}

extension DashboardViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return bikeData.registers.count
  }

  func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
    let id = bikeData.registers[indexPath.row].id
    if id == .trip {
      return UISwipeActionsConfiguration(actions: [reset(register: id, at: indexPath)])
    }
    if id == .map && connected {
      return UISwipeActionsConfiguration(actions: [switchMap(at: indexPath)])
    }
    return UISwipeActionsConfiguration(actions: [])
  }

  private func reset(register: BikeData.RegisterId, at indexPath: IndexPath) -> UIContextualAction {
    let action = UIContextualAction(style: .normal, title: "Reset") { (action, view, completion) in
      self.bikeData.resetRegisterFromUI(register)
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
      self.bikeData.setRegisterFromUI(BikeData.Register(id: .map, value: next, timestamp: Date().timeIntervalSinceReferenceDate))
      self.dataView.reloadRows(at: [indexPath], with: .none)
      completion(true)
    }
  }
}

extension DashboardViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = dataView.dequeueReusableCell(withIdentifier: "RegisterTableViewCell", for: indexPath)
    if let cell = cell as? RegisterTableViewCell {
      cell.setRegister(bikeData.registers[indexPath.row], connected: connected)
    }
    return cell
  }
}
