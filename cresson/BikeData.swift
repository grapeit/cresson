import Foundation

class BikeData: Decodable, Encodable {

  struct Register: Decodable, Encodable {
    let id: Int
    let value: Int

    enum CodingKeys: String, CodingKey {
      case id = "i"
      case value = "v"
    }

    func label() -> String {
      return String(format: "%02d: %08X (%d)", id, value, value)
    }
  }

  let status: String
  let registers: [Register]
  let lastError: Int
  let time: TimeInterval

  func statusLabel() -> String {
    return String(format: "%@ (e: %d, t: %.0f)", status, lastError, time)
  }
}
