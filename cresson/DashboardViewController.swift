import UIKit

class DashboardViewController: UIViewController {

  @IBOutlet weak var dataView: UITableView!
  @IBOutlet weak var statusLabel: UILabel!

  var btConnection = BtConnection()
  let bikeData = BikeData()
  var connected = false
  var observers = [Any]()

  override func viewDidLoad() {
    super.viewDidLoad()
    dataView.register(UINib(nibName: "RegisterTableViewCell", bundle: nil), forCellReuseIdentifier: "RegisterTableViewCell")
    dataView.delegate = self
    dataView.dataSource = self
    dataView.tableFooterView = UIView(frame: .zero)
    statusLabel.text = ""
    observers.append(NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: nil) { [weak self] _ in self?.bikeData.save() })
    observers.append(NotificationCenter.default.addObserver(forName: UIApplication.willTerminateNotification, object: nil, queue: nil) { [weak self] _ in self?.bikeData.save() })
    btConnection.delegate = self
    btConnection.start()
    bikeData.btConnection = btConnection
  }

  deinit {
    for observer in observers {
      NotificationCenter.default.removeObserver(observer)
    }
  }

  private func onConnectionStatusChanged() {
    UIApplication.shared.isIdleTimerDisabled = connected
    dataView.reloadData()
  }
}

extension DashboardViewController: BtConnectionDelegate {
  func status(_ status: String) {
    print(status)
    if connected && !btConnection.connected {
      bikeData.onConnectionLost()
      connected = false
      onConnectionStatusChanged()
    }
    statusLabel.text = status
  }

  func update(_ data: BikeUpdate) {
    bikeData.update(data)
    for cell in dataView.visibleCells {
      if let cell = cell as? RegisterTableViewCell, let id = cell.registerId, let register = bikeData.getRegister(id) {
        cell.setRegister(register, connected: connected)
      }
    }
    if connected != bikeData.connected {
      connected = bikeData.connected
      onConnectionStatusChanged()
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
    let action = UIContextualAction(style: .normal, title: "Reset") { (_, _, completion) in
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
    return UIContextualAction(style: .normal, title: "\(next)") { (_, _, completion) in
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
