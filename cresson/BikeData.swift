import Foundation


class BikeUpdate: Decodable, Encodable {

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


class BikeData {

  enum RegisterId: Int, CaseIterable {
    case gear = 11
    case throttle = 4
    case rpm = 9
    case speed = 12
    case coolant = 6
    case battery = 10

    case map = 1000

    case trip = -1
    case odometer = -2

    func isLive() -> Bool {
      return self.rawValue > 0
    }
  }

  struct Register {
    let id: RegisterId
    let value: Int
    let timestamp: TimeInterval
  }

  static var speedCompensation = 1.1 //TODO: empiric value, make it configurable

  var registers = [Register]()
  var logger = Logger()
  var status = String()
  var time: TimeInterval
  var connected = false
  var mapToSend: Int?
  weak var btConnection: BtConnection?


  init() {
    time = Date().timeIntervalSinceReferenceDate
    for id in RegisterId.allCases {
      if id.isLive(){
        setRegister(Register(id: id, value: 0, timestamp: time))
      } else {
        loadRegister(id)
      }
    }
  }

  func save() {
    for r in registers {
      if !r.id.isLive() {
        saveRegister(r)
      }
    }
  }

  func getRegister(_ id: RegisterId) -> Register? {
    return registers.first() { $0.id == id } ?? nil
  }

  func update(_ data: BikeUpdate) {
    status = String(format: "%@ (time: %.0lf/%.0lfms)", data.status, data.time, (Date().timeIntervalSinceReferenceDate - time) * 1000.0)
    time = Date().timeIntervalSinceReferenceDate
    for r in data.registers {
      guard let id = RegisterId(rawValue: r.id) else {
        continue
      }
      let newRegister = Register(id: id, value: r.value, timestamp: time)
      if id == .speed {
        updateOdometer(currentSpeed: newRegister)
      }
      setRegister(newRegister)
    }
    setRegister(Register(id: .map, value: data.map, timestamp: time))
    if let mapToSend = mapToSend, mapToSend != data.map {
      sendMap(mapToSend, withRetry: false)
    }
    logger.log(registers)
    connected = data.status == "bike is connected"
  }

  func setRegisterFromUI(_ register: Register) {
    if register.id == .map {
      sendMap(register.value, withRetry: true)
      return
    }
    setRegister(register)
    if !register.id.isLive() {
      saveRegister(register)
    }
  }

  func resetRegisterFromUI(_ id: RegisterId) {
    setRegisterFromUI(Register(id: id, value: 0, timestamp: Date().timeIntervalSinceReferenceDate))
  }

  private func setRegister(_ register: Register) {
    for (i, v) in registers.enumerated() {
      if v.id == register.id {
        registers[i] = register
        return
      }
    }
    registers.append(register)
  }

  private func sendMap(_ value: Int, withRetry retry: Bool) {
    guard let btConnection = btConnection else {
      return
    }
    mapToSend = retry ? value : nil
    var command = Array("map:".utf8)
    command.append(UInt8(value))
    btConnection.send(Data(bytes: command, count: command.count))
  }

  private func loadRegister(_ id: RegisterId) {
    let v = UserDefaults.standard.value(forKey: String(reflecting: id)) as? Int ?? 0
    setRegister(Register(id: id, value: v, timestamp: Date().timeIntervalSinceReferenceDate))
  }

  private func saveRegister(_ register: Register) {
    UserDefaults.standard.set(register.value, forKey: String(reflecting: register.id))
  }

  private func updateOdometer(currentSpeed: Register) {
    guard let oldSpeed = getRegister(.speed) else {
      return
    }
    let time = currentSpeed.timestamp - oldSpeed.timestamp
    let speedMs = ((oldSpeed.normalizeSpeed() + currentSpeed.normalizeSpeed()) / 2.0).kmh2ms()
    let distanceMm = Int((speedMs * time).m2mm().rounded())
    let add = { (r: RegisterId) in
      let v = self.getRegister(r)?.value ?? 0
      self.setRegister(Register(id: r, value: v + distanceMm, timestamp: currentSpeed.timestamp))
    }
    add(.odometer)
    add(.trip)
  }
}


extension BikeData.Register {
  // using km for distance, kh/h for speed, celsius for temperature, [0...1] for percentage
  func normalize() -> Double {
    switch id {
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

  func normalizeThrottle() -> Double {
    // set for killswitch set to ON, when killswitch is OFF bounds differ so using min(max())
    let lowerBound = 0x00D2
    let upperBound = 0x037A
    return min(1.0, max(0.0, Double(value - lowerBound) / Double(upperBound - lowerBound)))
  }

  func normalizeTemperature() -> Double {
    return Double(value - 48) / 1.6
  }

  func normalizeRpm() -> Double {
    return Double(((value & 0xFF00) >> 8) * 100 + (value & 0xFF))
  }

  func normalizeVoltage() -> Double {
    return Double(value) / 12.75
  }

  func normalizeSpeed() -> Double {
    return Double(((value & 0xFF00) >> 8) * 100 + (value & 0xFF)) / 2.0 * BikeData.speedCompensation
  }

  func normalizeOdometer() -> Double {
    return Double(value).mm2km()
  }

  func normalizeAsIs() -> Double {
    return Double(value)
  }

  func label() -> String {
    switch id {
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

  func throttleLabel() -> String {
    return String(format: "Throttle: %.0lf%%", normalizeThrottle() * 100.0)
  }

  func coolantLabel() -> String {
    let c = normalizeTemperature()
    return String(format: "Coolant: %.0lf°C | %.0lf°F", c, c.c2f())
  }

  func rpmLabel() -> String {
    return String(format: "RPM: %.0lf", normalizeRpm())
  }

  func batteryLabel() -> String {
    return String(format: "Battery: %.2lfV", normalizeVoltage())
  }

  func gearLabel() -> String {
    return "Gear: " + (value == 0 ? "N" : "\(value)")
  }

  func speedLabel() -> String {
    let kmh = normalizeSpeed()
    return String(format: "Speed: %.0lfkm/h | %.0lfmph", kmh, kmh.km2mi())
  }

  func odometerLabel() -> String {
    let km = normalizeOdometer()
    return String(format: "Odo: %.0lfkm | %.0lfmi", km, km.km2mi())
  }

  func tripLabel() -> String {
    let km = normalizeOdometer()
    return String(format: "Trip: %.2lfkm | %.2lfmi", km, km.km2mi())
  }

  func mapLabel() -> String {
    return "Fuel map: \(value)"
  }
}
