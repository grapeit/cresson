import Foundation

class TripMeterData {
  struct Register {
    let id: String
    var value: Double

    init(id: String) {
      self.id = id
      value = UserDefaults.standard.value(forKey: id) as? Double ?? 0.0
    }

    func save() {
      UserDefaults.standard.set(value, forKey: id)
    }
  }

  private var trip = Register(id: tripMeterRegisterId)
  private var prevSpeed: Double?
  private var timestamp: TimeInterval?

  private let registerSaveInterval = 20.0
  private var saveTimer: Timer!

  init() {
    saveTimer = Timer.scheduledTimer(withTimeInterval: registerSaveInterval, repeats: true) { [weak self] _ in self?.save() }
  }

  func save() {
    trip.save()
  }

  func reset() {
    trip.value = 0.0
    trip.save()
  }
}

extension TripMeterData.Register: DataRegister {
  var label: String {
    return String(format: "Trip: %.2lfkm | %.2lfmi", value.m2km(), value.m2mi())
  }
}

extension TripMeterData: CalculatedDataProvider {
  func calculate(_ data: [String: DataRegister]) -> [DataRegister] {
    guard let speed = (data[bikeSpeedRegisterId] ?? data[locationSpeedRegisterId])?.value else {
      return []
    }
    let currentTimestamp = Date().timeIntervalSinceReferenceDate
    if let prevSpeed = prevSpeed, let timestamp = timestamp {
      let time = currentTimestamp - timestamp
      let avgSpeed = (prevSpeed + speed) / 2.0
      let distance = avgSpeed * time
      trip.value += distance
    }
    prevSpeed = speed
    timestamp = currentTimestamp
    return [trip]
  }
}
