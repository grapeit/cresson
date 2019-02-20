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

    func label() -> String {
      return String(format: "%02d: %08X (%d)", id, value, value)
    }
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
