import Foundation

class TimerData {
  struct Register: DataRegister {
    let id: String
    var value: Double
    var label: String {
      let formatter = DateFormatter()
      formatter.dateStyle = .none
      formatter.timeStyle = .medium
      return id + ": " + formatter.string(from: Date(timeIntervalSinceReferenceDate: value))
    }

    init() {
      id = "timer"
      value = Date().timeIntervalSinceReferenceDate
    }
  }

  private let timeInterval = 0.333

  private var time = Register()
  private var timer: Timer!

  //PrimaryDataProvider
  weak var dataCollector: DataObserver?

  init() {
    timer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: true) { [weak self] _ in self?.advance() }
  }

  func advance() {
    time.value = Date().timeIntervalSinceReferenceDate
    idleCycle()
  }
}

extension TimerData: PrimaryDataProvider {
  func idleCycle() {
    dataCollector?.status(DataProviderStatus.online(""))
    dataCollector?.data(self.data)
  }
}

extension TimerData: DataProvider {
  var data: [DataRegister] {
    return [time]
  }

  func enumRegisterIds(id: (String) -> Void) {
    id(time.id)
  }
}
