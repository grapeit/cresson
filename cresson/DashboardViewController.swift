import UIKit

class DashboardViewController: UIViewController {

  @IBOutlet weak var dataView: UITableView!
  @IBOutlet weak var statusLabel: UILabel!

  var connected = false
  var observers = [Any]()

  override func viewDidLoad() {
    super.viewDidLoad()
    dataView.register(UINib(nibName: "RegisterTableViewCell", bundle: nil), forCellReuseIdentifier: "RegisterTableViewCell")
    dataView.delegate = self
    dataView.dataSource = self
    dataView.tableFooterView = UIView(frame: .zero)
    statusLabel.text = ""
    CressonApp.shared.dataCollector.addObserver(self)
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

extension DashboardViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return CressonApp.shared.ninjaData.data.count
  }

  func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
    let id = CressonApp.shared.ninjaData.data[indexPath.row].rId
    if id == .trip {
      return UISwipeActionsConfiguration(actions: [reset(register: id, at: indexPath)])
    }
    if id == .map && connected {
      return UISwipeActionsConfiguration(actions: [switchMap(at: indexPath)])
    }
    return UISwipeActionsConfiguration(actions: [])
  }

  private func reset(register: NinjaData.RegisterId, at indexPath: IndexPath) -> UIContextualAction {
    let action = UIContextualAction(style: .normal, title: "Reset") { (_, _, completion) in
      CressonApp.shared.ninjaData.resetRegisterFromUI(register)
      self.dataView.reloadRows(at: [indexPath], with: .none)
      completion(true)
    }
    action.backgroundColor = .red
    return action
  }

  private func switchMap(at indexPath: IndexPath) -> UIContextualAction {
    let current = CressonApp.shared.ninjaData.getRegister(.map)?.rValue ?? 0
    let next = current == 1 ? 2 : 1
    return UIContextualAction(style: .normal, title: "\(next)") { (_, _, completion) in
      CressonApp.shared.ninjaData.setRegisterFromUI(NinjaData.Register(rId: .map, rValue: next, timestamp: Date().timeIntervalSinceReferenceDate))
      self.dataView.reloadRows(at: [indexPath], with: .none)
      completion(true)
    }
  }
}

extension DashboardViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = dataView.dequeueReusableCell(withIdentifier: "RegisterTableViewCell", for: indexPath)
    if let cell = cell as? RegisterTableViewCell {
      cell.setRegister(CressonApp.shared.ninjaData.data[indexPath.row], connected: connected)
    }
    return cell
  }
}

extension DashboardViewController: DataObserver {
  func status(_ status: DataProviderStatus) {
    let connected = status.isOnline
    if connected != self.connected {
      self.connected = connected
      onConnectionStatusChanged()
    }
    statusLabel.text = status.message
  }

  func data(_ data: [DataRegister]) {
    for cell in dataView.visibleCells {
      if let cell = cell as? RegisterTableViewCell, let id = cell.registerId, let register = CressonApp.shared.dataCollector.getRegister(id) {
        cell.setRegister(register, connected: connected)
      }
    }
  }
}
