import Foundation

class TimerData: PrimaryDataProvider {
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
      id = timerRegisterId
      value = Date().timeIntervalSinceReferenceDate
    }
  }

  private let timeInterval = 0.333

  private var time = Register()
  private var timer: Timer!

  //PrimaryDataProvider
  weak var dataCollector: DataCollector?

  init() {
    timer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: true) { [weak self] _ in self?.advance() }
  }

  func advance() {
    time.value = Date().timeIntervalSinceReferenceDate
    dataCollector?.status(DataProviderStatus.online(""))
    dataCollector?.data([time])
  }
}
