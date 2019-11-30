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
  }

  struct Register {
    let rId: RegisterId
    let rValue: Int
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

  private var status = DataProviderStatus.offline("")
  private var currentdata = [RegisterId: Register]()

  private var dataCollected = Data()
  private var mapToSend: Int?
  private var btConnection = BtConnection()

  //PrimaryDataProvider
  weak var dataCollector: DataObserver?

  init() {
    for id in RegisterId.allCases {
      currentdata[id] = Register(rId: id, rValue: 0)
    }
    btConnection.delegate = self
    btConnection.start()
  }

  func sendMap(_ value: Int, withRetry retry: Bool) {
    mapToSend = retry ? value : nil
    var command = "map:".data(using: .ascii)!
    command.append([UInt8(value)], count: 1)
    btConnection.send(command)
  }

  private func update(_ data: Update) {
    for register in data.registers {
      guard let id = RegisterId(rawValue: register.id) else {
        continue
      }
      currentdata[id] = Register(rId: id, rValue: register.value)
    }
    currentdata[.map] = Register(rId: .map, rValue: data.map)
    if let mapToSend = mapToSend, mapToSend != data.map {
      sendMap(mapToSend, withRetry: false)
    }
    let statusString = String(format: "%@ (time: %.0lfms)", data.status, data.time)
    status = data.status == "bike is connected" ? .online(statusString) : .offline(data.status)
    dataCollector?.status(status)
    dataCollector?.data(currentdata.map { $0.value })
  }
}

extension NinjaData: PrimaryDataProvider {
  func idleCycle() {
    dataCollector?.status(status)
    dataCollector?.data(self.data)
  }
}

extension NinjaData: DataProvider {
  var data: [DataRegister] {
    return currentdata.map { $0.value }
  }

  func enumRegisterIds(id: (String) -> Void) {
    for i in RegisterId.allCases {
      id(Register(rId: i, rValue: 0).id)
    }
  }
}

extension NinjaData: BtConnectionDelegate {
  func status(_ status: String) {
    self.status = btConnection.connected ? .online(status) : .offline(status)
    dataCollector?.status(self.status)
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

  func mapLabel() -> String {
    return "Fuel map: \(rValue)"
  }
}

extension NinjaData.Register: DataRegister {
  var id: String {
    switch rId {
    case .throttle:
      return "k_throttle"
    case .coolant:
      return "k_coolant"
    case .rpm:
      return "k_rpm"
    case .battery:
      return "k_battery"
    case .gear:
      return "k_gear"
    case .speed:
      return speedRegisterId
    case .map:
      return throttleRegisterId
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
    case .map:
      return mapLabel()
    }
  }
}
