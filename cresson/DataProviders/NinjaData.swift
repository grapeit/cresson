import Foundation

class NinjaData {

  enum RegisterId: Int, CaseIterable {
    case gear = 11
    case throttle = 4
    case rpm = 9
    case speed = 12
    case coolant = 6
    case battery = 10

    case map = 1000

    //TODO: move trip and odo to calculated data provider, remove timestamp from register
    case trip = -1
    case odometer = -2

    func isLive() -> Bool {
      return self.rawValue > 0
    }
  }

  struct Register {
    let rId: RegisterId
    let rValue: Int
    let timestamp: TimeInterval
  }

  class Update: Decodable, Encodable {

    struct Register: Decodable, Encodable {
      let id: Int
      let value: Int

      enum CodingKeys: String, CodingKey {
        case id = "i"
        case value = "v"
      }
    }

    let status: String
    let registers: [Register]
    let map: Int
    let lastError: Int
    let time: TimeInterval
  }

  static var speedCompensation = 1.1 //TODO: empiric value, make it configurable

  let registerSaveInterval = 20.0

  // conforming to DataProvider
  var status = DataProviderStatus.offline("")
  var data = [Register]()

  var dataCollected = Data()
  var time: TimeInterval
  var mapToSend: Int?
  var btConnection = BtConnection()
  var saveTimer: Timer!

  init() {
    time = Date().timeIntervalSinceReferenceDate
    for id in RegisterId.allCases {
      if id.isLive() {
        setRegister(Register(rId: id, rValue: 0, timestamp: time))
      } else {
        loadRegister(id)
      }
    }
    saveTimer = Timer.scheduledTimer(withTimeInterval: registerSaveInterval, repeats: true) { [weak self] _ in self?.save() }
    btConnection.delegate = self
    btConnection.start()
  }

  func save() {
    for register in data {
      if !register.rId.isLive() {
        saveRegister(register)
      }
    }
  }

  func getRegister(_ id: RegisterId) -> Register? {
    return data.first { $0.rId == id } ?? nil
  }

  func setRegisterFromUI(_ register: Register) {
    if register.rId == .map {
      sendMap(register.rValue, withRetry: true)
      return
    }
    setRegister(register)
    if !register.rId.isLive() {
      saveRegister(register)
    }
  }

  func resetRegisterFromUI(_ id: RegisterId) {
    setRegisterFromUI(Register(rId: id, rValue: 0, timestamp: Date().timeIntervalSinceReferenceDate))
  }

  private func setRegister(_ register: Register) {
    for (i, value) in data.enumerated() where value.rId == register.rId {
      data[i] = register
      return
    }
    data.append(register)
  }

  private func sendMap(_ value: Int, withRetry retry: Bool) {
    mapToSend = retry ? value : nil
    var command = "map:".data(using: .ascii)!
    command.append([UInt8(value)], count: 1)
    btConnection.send(command)
  }

  private func loadRegister(_ id: RegisterId) {
    let value = UserDefaults.standard.value(forKey: String(reflecting: id)) as? Int ?? 0
    setRegister(Register(rId: id, rValue: value, timestamp: Date().timeIntervalSinceReferenceDate))
  }

  private func saveRegister(_ register: Register) {
    UserDefaults.standard.set(register.rValue, forKey: String(reflecting: register.rId))
  }

  private func updateOdometer(currentSpeed: Register) {
    guard let oldSpeed = getRegister(.speed) else {
      return
    }
    let time = currentSpeed.timestamp - oldSpeed.timestamp
    let speedMs = (oldSpeed.normalizeSpeed() + currentSpeed.normalizeSpeed()) / 2.0
    let distanceMm = Int((speedMs * time).m2mm().rounded())
    let add = { (id: RegisterId) in
      let value = self.getRegister(id)?.rValue ?? 0
      self.setRegister(Register(rId: id, rValue: value + distanceMm, timestamp: currentSpeed.timestamp))
    }
    add(.odometer)
    add(.trip)
  }

  private func update(_ data: Update) {
    time = Date().timeIntervalSinceReferenceDate
    for register in data.registers {
      guard let id = RegisterId(rawValue: register.id) else {
        continue
      }
      let newRegister = Register(rId: id, rValue: register.value, timestamp: time)
      if id == .speed {
        updateOdometer(currentSpeed: newRegister)
      }
      setRegister(newRegister)
    }
    setRegister(Register(rId: .map, rValue: data.map, timestamp: time))
    if let mapToSend = mapToSend, mapToSend != data.map {
      sendMap(mapToSend, withRetry: false)
    }
    let statusString = String(format: "%@ (time: %.0lf/%.0lfms)", data.status, data.time, (Date().timeIntervalSinceReferenceDate - time) * 1000.0)
    status = data.status == "bike is connected" ? .online(statusString) : .offline(data.status)
    CressonApp.shared.dataCollector.status(status)
    CressonApp.shared.dataCollector.data(self.data)
  }
}

extension NinjaData: BtConnectionDelegate {
  func status(_ status: String) {
    self.status = btConnection.connected ? .online(status) : .offline(status)
    CressonApp.shared.dataCollector.status(self.status)
  }

  func update(_ data: Data) {
    dataCollected += data
    while let i = dataCollected.firstIndex(of: UInt8(0x0A)) { // 0x0A = `\n`
      if let j = try? JSONDecoder().decode(Update.self, from: dataCollected[..<i]) {
        update(j)
      }
      dataCollected = dataCollected[dataCollected.index(i, offsetBy: 1)...]
    }
  }
}

extension NinjaData.Register {
  func normalizeThrottle() -> Double {
    // set for killswitch set to ON, when killswitch is OFF bounds differ so using min(max())
    let lowerBound = 0x00D2
    let upperBound = 0x037A
    return min(1.0, max(0.0, Double(rValue - lowerBound) / Double(upperBound - lowerBound)))
  }

  func normalizeTemperature() -> Double {
    return (Double(rValue - 48) / 1.6).c2k()
  }

  func normalizeRpm() -> Double {
    return Double(((rValue & 0xFF00) >> 8) * 100 + (rValue & 0xFF))
  }

  func normalizeVoltage() -> Double {
    return Double(rValue) / 12.75
  }

  func normalizeSpeed() -> Double {
    return Double(((rValue & 0xFF00) >> 8) * 100 + (rValue & 0xFF)).kmh2ms() / 2.0 * NinjaData.speedCompensation
  }

  func normalizeOdometer() -> Double {
    return Double(rValue).mm2m()
  }

  func normalizeAsIs() -> Double {
    return Double(rValue)
  }

  func throttleLabel() -> String {
    return String(format: "Throttle: %.0lf%%", normalizeThrottle() * 100.0)
  }

  func coolantLabel() -> String {
    let temp = normalizeTemperature()
    return String(format: "Coolant: %.0lf°C | %.0lf°F", temp.k2c(), temp.k2f())
  }

  func rpmLabel() -> String {
    return String(format: "RPM: %.0lf", normalizeRpm())
  }

  func batteryLabel() -> String {
    return String(format: "Battery: %.2lfV", normalizeVoltage())
  }

  func gearLabel() -> String {
    return "Gear: " + (rValue == 0 ? "N" : "\(rValue)")
  }

  func speedLabel() -> String {
    let mps = normalizeSpeed()
    return String(format: "Speed: %.0lfkm/h | %.0lfmph", mps.m2km(), mps.m2mi())
  }

  func odometerLabel() -> String {
    let dist = normalizeOdometer()
    return String(format: "Odo: %.0lfkm | %.0lfmi", dist.m2km(), dist.m2mi())
  }

  func tripLabel() -> String {
    let dist = normalizeOdometer()
    return String(format: "Trip: %.2lfkm | %.2lfmi", dist.m2km(), dist.m2mi())
  }

  func mapLabel() -> String {
    return "Fuel map: \(rValue)"
  }
}

extension NinjaData.Register: DataRegister {
  var id: String {
    switch rId {
    case .throttle:
      return "k-throttle"
    case .coolant:
      return "k-coolant"
    case .rpm:
      return "k-rpm"
    case .battery:
      return "k-battery"
    case .gear:
      return "k-gear"
    case .speed:
      return "k-speed"
    case .odometer:
      return "k-odometer"
    case .trip:
      return "k-trip"
    case .map:
      return "k-map"
    }
  }

  var value: Double {
    switch rId {
    case .throttle:
      return normalizeThrottle()
    case .coolant:
      return normalizeTemperature()
    case .rpm:
      return normalizeRpm()
    case .battery:
      return normalizeVoltage()
    case .speed:
      return normalizeSpeed()
    case .odometer, .trip:
      return normalizeOdometer()
    case .gear, .map:
      return normalizeAsIs()
    }
  }

  var label: String {
    switch rId {
    case .throttle:
      return throttleLabel()
    case .coolant:
      return coolantLabel()
    case .rpm:
      return rpmLabel()
    case .battery:
      return batteryLabel()
    case .gear:
      return gearLabel()
    case .speed:
      return speedLabel()
    case .odometer:
      return odometerLabel()
    case .trip:
      return tripLabel()
    case .map:
      return mapLabel()
    }
  }
}
