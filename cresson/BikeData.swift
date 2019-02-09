import Foundation

class BikeData: Decodable, Encodable {
  let status: String
  let time: TimeInterval
  let registers: [String: Int]
}
