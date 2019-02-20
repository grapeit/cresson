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

  struct Register {
    let id: Int
    let value: Int
    let timestamp: TimeInterval
  }

  var registers = [Register]()
  var status = String()

  func getRegister(_ id: Int) -> Register? {
    return registers.first() { $0.id == id } ?? nil
  }

  func update(_ data: BikeUpdate) -> Bool {
    var reload = false
    for r in data.registers {
      let newRegister = Register(id: r.id, value: r.value, timestamp: Date().timeIntervalSinceReferenceDate)
      var found = false
      for (i, v) in registers.enumerated() {
        if v.id == r.id {
          registers[i] = newRegister
          found = true
          break
        }
      }
      if !found {
        registers.append(newRegister)
        reload = true
      }
    }
    registers.sort { return $0.id < $1.id }
    status = String(format: "%@ (e: %d, t: %.0f)", data.status, data.lastError, data.time)
    return reload
  }
}


extension BikeData.Register {
  func label() -> String {
    switch id {
    case 4:
      return throttleLabel()
    case 6:
      return coolantLabel()
    case 9:
      return rpmLabel()
    case 10:
      return batteryLabel()
    case 11:
      return gearLabel()
    case 12:
      return speedLabel()
    default:
      return String(format: "%02d: %08X (%d)", id, value, value)
    }
  }

  func throttleLabel() -> String {
    let v = Double(value - 0x00D2) / Double(0x037A - 0x00D2) * 100.0
    return String(format: "Throttle: %.0lf%% (%08X)", min(100.0, max(0.0, v)), value)
  }

  func coolantLabel() -> String {
    let c = Double(value - 48) / 1.6
    return String(format: "Coolant: %.1lfC | %.1lfF", c, (c * 9.0 / 5.0) + 32.0)
  }

  func rpmLabel() -> String {
    return String(format: "RPM: %d", ((value & 0xFF00) >> 8) * 100 + (value & 0xFF))
  }

  func batteryLabel() -> String {
    return String(format: "Battery: %.2lfV", Double(value) / 12.75)
  }

  func gearLabel() -> String {
    return String(format: "Gear: %d", value)
  }

  func speedLabel() -> String {
    let km = ((value & 0xFF00) >> 8) * 100 + (value & 0xFF)
    return String(format: "Speed: %dkm/h | %.0lfmph", km, Double(km) * 1.609344)
  }
}
