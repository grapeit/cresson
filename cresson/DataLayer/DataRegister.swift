import Foundation

/*
 Using SI to canonicalize data. All values are double precision floating point.
  time - second
  distance - meter
  temperature - kelvin
  voltage - volt

 Derivative types:
  timestamp - seconds from epoch
  speed - meter/second
  acceleration - meter/second^2

 Other:
  percentage - [0...1]
  gear position, throttle map - values as is
 */

protocol DataRegister {
  var id: String { get }
  var value: Double { get }
  var label: String { get }
}
