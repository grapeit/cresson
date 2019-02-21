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

  func testData() {
    status = "testing"
    let t = Date().timeIntervalSinceReferenceDate
    registers.append(Register(id: 1, value: 100, timestamp: t))
    registers.append(Register(id: 2, value: 200, timestamp: t))
    registers.append(Register(id: 3, value: 300, timestamp: t))
    registers.append(Register(id: 4, value: 400, timestamp: t))
    registers.append(Register(id: 5, value: 500, timestamp: t))
    registers.append(Register(id: 6, value: 600, timestamp: t))
  }

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
    status = String(format: "%@ (time: %.0lfms)", data.status, data.time)
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
    let kmh = Double(((value & 0xFF00) >> 8) * 100 + (value & 0xFF)) / 2.0
    return String(format: "Speed: %.0lfkm/h | %.0lfmph", kmh, kmh / 1.609344)
  }
}
