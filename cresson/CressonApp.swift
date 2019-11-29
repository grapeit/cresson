import UIKit

class CressonApp {
  let dataCollector = DataCollector()
  var ninjaData: NinjaData!
  var logger: Logger!

  private var observers = [Any]()

  static let shared = CressonApp()

  private init() {
    observers.append(NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: nil) { [weak self] _ in self?.saveData() })
    observers.append(NotificationCenter.default.addObserver(forName: UIApplication.willTerminateNotification, object: nil, queue: nil) { [weak self] _ in self?.saveData() })
  }

  deinit {
    for observer in observers {
      NotificationCenter.default.removeObserver(observer)
    }
  }

  func connect() {
    ninjaData = NinjaData()
    logger = Logger()
  }

  func saveData() {
    ninjaData?.save()
  }
}
