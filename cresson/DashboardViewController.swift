import UIKit

class DashboardViewController: UIViewController {

  @IBOutlet weak var dataView: UITableView!
  @IBOutlet weak var statusLabel: UILabel!

  var connected = false
  var registerIds = [String]()

  override func viewDidLoad() {
    super.viewDidLoad()
    dataView.register(UINib(nibName: "RegisterTableViewCell", bundle: nil), forCellReuseIdentifier: "RegisterTableViewCell")
    dataView.delegate = self
    dataView.dataSource = self
    dataView.tableFooterView = UIView(frame: .zero)
    statusLabel.text = ""
    CressonApp.shared.dataCollector.addObserver(self)
    registerIds = [
      //"timer",
      "k_gear",
      "k_rpm",
      "k_speed",
      "k_throttle",
      "k_coolant",
      "k_battery",
      //"l_latitude",
      //"l_longitude",
      "l_speed",
      "l_altitude",
      "l_heading",
      //"l_hor_accuracy",
      //"l_vert_accuracy",
      "l_head_accuracy",
      "c_trip"
    ]
  }

  private func onConnectionStatusChanged() {
    UIApplication.shared.isIdleTimerDisabled = connected
    dataView.reloadData()
  }
}

extension DashboardViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return registerIds.count
  }

  func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
    guard indexPath.row < registerIds.count else {
      return nil
    }
    let id = registerIds[indexPath.row]
    if id == tripMeterRegisterId {
      return UISwipeActionsConfiguration(actions: [resetTrip(at: indexPath)])
    }
    if id == fuelMapRegisterId && connected {
      return UISwipeActionsConfiguration(actions: [switchMap(at: indexPath)])
    }
    return UISwipeActionsConfiguration(actions: [])
  }

  private func resetTrip(at indexPath: IndexPath) -> UIContextualAction {
    let action = UIContextualAction(style: .normal, title: "Reset") { (_, _, completion) in
      CressonApp.shared.tripMeterData?.reset()
      self.dataView.reloadRows(at: [indexPath], with: .none)
      completion(true)
    }
    action.backgroundColor = .red
    return action
  }

  private func switchMap(at indexPath: IndexPath) -> UIContextualAction {
    let current = CressonApp.shared.dataCollector.getRegister(fuelMapRegisterId)?.value ?? 0
    let next = current == 1 ? 2 : 1
    return UIContextualAction(style: .normal, title: "\(next)") { (_, _, completion) in
      CressonApp.shared.ninjaData.sendMap(next, withRetry: true)
      self.dataView.reloadRows(at: [indexPath], with: .none)
      completion(true)
    }
  }

  private func getRegister(_ id: String) -> DataRegister {
    return CressonApp.shared.dataCollector.getRegister(id) ?? DummyDataRegister(id)
  }
}

extension DashboardViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = dataView.dequeueReusableCell(withIdentifier: "RegisterTableViewCell", for: indexPath)
    guard indexPath.row < registerIds.count else {
      return cell
    }
    let id = registerIds[indexPath.row]
    if let cell = cell as? RegisterTableViewCell {
      cell.setRegister(getRegister(id), connected: connected)
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

  func data(_ data: [String: DataRegister]) {
    for cell in dataView.visibleCells {
      if let cell = cell as? RegisterTableViewCell, let id = cell.registerId, let register = data[id] {
        cell.setRegister(register, connected: connected)
      }
    }
  }
}
