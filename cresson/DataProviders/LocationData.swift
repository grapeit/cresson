import CoreLocation

class LocationData: NSObject {
  struct Register {
    let id: String
    var value: Double

    init(id: String) {
      self.id = id
      value = 0.0
    }
  }

  private let locationManager = CLLocationManager()

  private var locationAvailable = false
  private var latitude = Register(id: "l_latitude")
  private var longitude = Register(id: "l_longitude")
  private var altitude = Register(id: "l_altitude")
  private var speed = Register(id: "l_speed")
  private var heading = Register(id: "l_heading")
  private var horAccuracy = Register(id: "l_hor_accuracy")
  private var vertAccuracy = Register(id: "l_vert_accuracy")
  private var headAccuracy = Register(id: "l_head_accuracy")

  override init() {
    super.init()
    locationManager.delegate = self
    locationManager.requestWhenInUseAuthorization()
    locationManager.startUpdatingLocation()
    locationManager.startUpdatingHeading()
  }

  private var allRegisters: [DataRegister] {
    return [latitude, longitude, horAccuracy, altitude, vertAccuracy, speed, heading, headAccuracy]
  }

  private var headingRegisters: [DataRegister] {
    return [heading, headAccuracy]
  }
}

extension LocationData: CLLocationManagerDelegate {
  func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
    locationAvailable = status == .authorizedAlways || status == .authorizedWhenInUse
  }

  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    guard let location = locations.last else {
      return
    }
    latitude.value = location.coordinate.latitude
    longitude.value = location.coordinate.longitude
    altitude.value = location.altitude
    if location.speed > 0.0 {
      speed.value = location.speed
    } else {
      speed.value = 0.0
    }
    horAccuracy.value = location.horizontalAccuracy
    vertAccuracy.value = location.verticalAccuracy
  }

  func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
    heading.value = newHeading.trueHeading
    headAccuracy.value = newHeading.headingAccuracy
  }
}

extension LocationData.Register: DataRegister {
  var label: String {
    switch id {
    case "l_speed":
      return String(format: "speed: %.1lfkm/h | %.1lfmph", value.ms2kmh(), value.ms2mph())
    case "l_heading":
      return "heading: " + headingLabel() + String(format: " (%.1lf\u{00B0})", value)
    default:
      return id.dropFirst(2) + String(format: ": %.6lg", value)
    }
  }

  func headingLabel() -> String {
    guard value >= 0 && value < 360 else {
      return "-"
    }
    let head = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
    let section = 360.0 / Double(head.count)
    let index = (value + section / 2.0) / section
    return head[Int(index) % head.count]
  }
}

extension LocationData: SecondaryDataProvider {
  func getData() -> [DataRegister] {
    if !locationAvailable {
      return headingRegisters
    }
    return allRegisters
  }
}
