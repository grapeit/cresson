import Foundation

enum DataProviderStatus: Equatable {
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

protocol DataProvider {
  var status: DataProviderStatus { get }
  var data: [DataRegister] { get }
}

protocol DataObserver {
  func status(_ status: DataProviderStatus)
  func data(_ data: [DataRegister])
}
