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
      return "\(id): \(value)"
    }
  }

  let status: String
  let time: TimeInterval
  let registers: [Register]
}
