import Foundation

extension Double {
  func m2mm() -> Double {
    return self * 1000.0
  }

  func mm2km() -> Double {
    return self / 1000000.0
  }

  func km2mi() -> Double {
    return self / 1.609344
  }

  func kmh2ms() -> Double {
    return self / 3.6
  }

  func c2f() -> Double {
    return (self * 9.0 / 5.0) + 32.0
  }
}
