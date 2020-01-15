import Foundation

enum DataProviderStatus {
  case offline(String)
  case online(String)

  var message: String {
    switch self {
    case .offline(let msg), .online(let msg):
      return msg
    }
  }

  var isOnline: Bool {
    switch self {
    case .offline:
      return false
    case .online:
      return true
    }
  }
}

protocol PrimaryDataProvider {
  var dataCollector: DataCollector? { get set }
}

protocol SecondaryDataProvider {
  func getData() -> [DataRegister]
}

protocol CalculatedDataProvider {
  func calculate(_ data: [String: DataRegister]) -> [DataRegister]
}

protocol DataObserver: class {
  func status(_ status: DataProviderStatus)
  func data(_ data: [String: DataRegister])
}
