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
  let lastError: Int
  let time: TimeInterval
}


class BikeData {

  enum RegisterId: Int {
    case throttle = 4
    case coolant = 6
    case rpm = 9
    case battery = 10
    case gear = 11
    case speed = 12

    // calculated values
    case odometer = 1000
    case trip = 1001
  }

  struct Register {
    let id: RegisterId
    let value: Int
    let timestamp: TimeInterval
  }

  var registers = [Register]()
  var status = String()
  var time: TimeInterval


  init() {
    time = Date().timeIntervalSinceReferenceDate
    loadRegister(.odometer)
    loadRegister(.trip)
  }

  func save() {
    saveRegister(.odometer)
    saveRegister(.trip)
  }

  func getRegister(_ id: RegisterId) -> Register? {
    return registers.first() { $0.id == id } ?? nil
  }

  func update(_ data: BikeUpdate) -> Bool {
    status = String(format: "%@ (time: %.0lf/%.0lfms)", data.status, data.time, (Date().timeIntervalSinceReferenceDate - time) * 1000.0)
    time = Date().timeIntervalSinceReferenceDate
    var reload = false
    for r in data.registers {
      guard let id = RegisterId(rawValue: r.id) else {
        continue
      }
      let newRegister = Register(id: id, value: r.value, timestamp: time)
      if id == .speed {
        reload = updateOdometer(currentSpeed: newRegister) || reload
      }
      reload = setRegister(newRegister) || reload
    }
    if reload {
      registers.sort { return $0.id.rawValue < $1.id.rawValue }
    }
    return reload
  }

  func resetRegister(_ id: RegisterId) {
    setRegister(Register(id: id, value: 0, timestamp: Date().timeIntervalSinceReferenceDate))
  }

  @discardableResult private func setRegister(_ register: Register) -> Bool {
    for (i, v) in registers.enumerated() {
      if v.id == register.id {
        registers[i] = register
        return false
      }
    }
    registers.append(register)
    return true
  }

  private func loadRegister(_ id: RegisterId) {
    let v = UserDefaults.standard.value(forKey: String(reflecting: id)) as? Int ?? 0
    setRegister(Register(id: id, value: v, timestamp: Date().timeIntervalSinceReferenceDate))
  }

  private func saveRegister(_ id: RegisterId) {
    if let v = getRegister(id)?.value {
      UserDefaults.standard.set(v, forKey: String(reflecting: id))
    }
  }

  private func updateOdometer(currentSpeed: Register) -> Bool {
    guard let oldSpeed = getRegister(.speed) else {
      return false
    }
    let time = currentSpeed.timestamp - oldSpeed.timestamp
    let speedMs = ((oldSpeed.speedValueKmh() + currentSpeed.speedValueKmh()) / 2.0).kmh2ms()
    let distanceMm = Int((speedMs * time).m2mm().rounded())
    let add = { (r: RegisterId) -> Bool in
      let v = self.getRegister(r)?.value ?? 0
      return self.setRegister(Register(id: r, value: v + distanceMm, timestamp: currentSpeed.timestamp))
    }
    let co = add(.odometer)
    let ct = add(.trip)
    return co || ct
  }
}


extension BikeData.Register {
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
    }
  }

  func throttleLabel() -> String {
    let v = Double(value - 0x00D2) / Double(0x037A - 0x00D2) * 100.0
    return String(format: "Throttle: %.0lf%%", min(100.0, max(0.0, v)))
  }

  func coolantLabel() -> String {
    let c = Double(value - 48) / 1.6
    return String(format: "Coolant: %.0lf°C | %.0lf°F", c, c.c2f())
  }

  func rpmLabel() -> String {
    return String(format: "RPM: %d", ((value & 0xFF00) >> 8) * 100 + (value & 0xFF))
  }

  func batteryLabel() -> String {
    return String(format: "Battery: %.2lfV", Double(value) / 12.75)
  }

  func gearLabel() -> String {
    return "Gear: " + (value == 0 ? "N" : "\(value)")
  }

  func speedLabel() -> String {
    let kmh = speedValueKmh()
    return String(format: "Speed: %.0lfkm/h | %.0lfmph", kmh, kmh.km2mi())
  }

  func odometerLabel() -> String {
    let km = Double(value).mm2km()
    return String(format: "Odo: %.0lfkm | %.0lfmi", km, km.km2mi())
  }

  func tripLabel() -> String {
    let km = Double(value).mm2km()
    return String(format: "Trip: %.2lfkm | %.2lfmi", km, km.km2mi())
  }

  func speedValueKmh() -> Double {
    return Double(((value & 0xFF00) >> 8) * 100 + (value & 0xFF)) / 2.0
  }
}
