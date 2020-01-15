import UIKit

class CressonApp {
  var dataCollector: DataCollector!
  var timerData: TimerData!
  var ninjaData: NinjaData!
  var locationData: LocationData!
  var tripMeterData: TripMeterData!
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
    dataCollector = DataCollector()
    timerData = TimerData()
    ninjaData = NinjaData()
    locationData = LocationData()
    tripMeterData = TripMeterData()
    logger = Logger()
    dataCollector.primarySource = timerData//ninjaData//
    dataCollector.addSecondarySource(locationData)
    dataCollector.addCalculatedSource(tripMeterData)
    dataCollector.primarySource.dataCollector = dataCollector
    dataCollector.addObserver(logger)
    //NOTE: view controllers register as data observers themselfs
  }

  func disconnect() {
    dataCollector = nil
    //timerData = nil
    ninjaData = nil
    //locationData = nil
    tripMeterData = nil
    logger = nil
  }

  func saveData() {
    tripMeterData?.save()
  }
}
