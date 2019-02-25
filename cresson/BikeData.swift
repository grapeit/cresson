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

  private func setRegister(_ register: Register) -> Bool {
    for (i, v) in registers.enumerated() {
      if v.id == register.id {
        registers[i] = register
        return false
      }
    }
    registers.append(register)
    return true
  }

  private func updateOdometer(currentSpeed: Register) -> Bool {
    guard let oldSpeed = getRegister(.speed) else {
      return false
    }
    let time = currentSpeed.timestamp - oldSpeed.timestamp
    let speedKmh = Double(oldSpeed.speedValueKmh2() + currentSpeed.speedValueKmh2()) / 2.0 / 2.0
    let speedMs = speedKmh / 3.6
    let distanceMm = Int((speedMs * time * 1000.0).rounded())
    let odo = getRegister(.odometer)?.value ?? 0
    return setRegister(Register(id: .odometer, value: odo + distanceMm, timestamp: currentSpeed.timestamp))
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
    }
  }

  func throttleLabel() -> String {
    let v = Double(value - 0x00D2) / Double(0x037A - 0x00D2) * 100.0
    return String(format: "Throttle: %.0lf%%", min(100.0, max(0.0, v)))
  }

  func coolantLabel() -> String {
    let c = Double(value - 48) / 1.6
    return String(format: "Coolant: %.0lf°C | %.0lf°F", c, (c * 9.0 / 5.0) + 32.0)
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
    let kmh = Double(speedValueKmh2()) / 2.0
    return String(format: "Speed: %.0lfkm/h | %.0lfmph", kmh, kmh / 1.609344)
  }

  func odometerLabel() -> String {
    let km = Double(value) / 1000000.0
    return String(format: "Odo: %.2lfkm | %.2lfmi", km, km / 1.609344)
  }

  func speedValueKmh2() -> Int {
    return ((value & 0xFF00) >> 8) * 100 + (value & 0xFF)
  }
}
