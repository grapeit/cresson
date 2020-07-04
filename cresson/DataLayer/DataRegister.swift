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
  gear position, throttle map - value as is
  direction - degrees, north is 0, east is 90, south is 180, west is 270
*/

/*
 Registers ids
 - Motorcycle data (K-line)
  - k_throttle
  - k_coolant
  - k_rpm
  - k_battery
  - k_gear
  - k_speed
 - Power commander map switch
  - s_map
 - Location data
  - l_latitude
  - l_longitude
  - l_altitude
  - l_speed
  - l_heading
  - l_hor_accuracy
  - l_vert_accuracy
  - l_head_accuracy
 - Calculated data
  - c_trip
*/

let timerRegisterId = "timer"
let fuelMapRegisterId = "s_map"
let bikeSpeedRegisterId = "k_speed"
let locationSpeedRegisterId = "l_speed"
let tripMeterRegisterId = "c_trip"

protocol DataRegister {
  var id: String { get }
  var value: Double { get }
  var label: String { get }
}

class DummyDataRegister: DataRegister {
  var id: String

  init (_ id: String) {
    self.id = id
  }

  var value: Double {
    return 0.0
  }

  var label: String {
    return "[" + id + "]"
  }
}
