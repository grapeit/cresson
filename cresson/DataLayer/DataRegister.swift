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

/*
 Registers ids
 - Motorcycle data (K-line + power commander map switch)
  - k_throttle
  - k_coolant
  - k_rpm
  - k_battery
  - k_gear
  - k_speed
  - k_map
 - Calculated data
  - c_trip
*/

let throttleRegisterId = "k_map"
let speedRegisterId = "k_speed"
let tripMeterRegisterId = "c_trip"

protocol DataRegister {
  var id: String { get }
  var value: Double { get }
  var label: String { get }
}
