import Foundation

extension Double {
  func m2km() -> Double {
    return self * 1000.0
  }

  func m2mi() -> Double {
    return self * 1609.344
  }

  func kmh2ms() -> Double {
    return self / 3.6
  }

  func c2k() -> Double {
    return self + 273.15
  }

  func k2c() -> Double {
    return self - 273.15
  }

  func k2f() -> Double {
    return (k2c() * 9.0 / 5.0) + 32.0
  }
}
