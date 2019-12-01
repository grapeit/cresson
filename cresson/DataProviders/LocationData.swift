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
    return id.dropFirst(2) + String(format: ": %.6lg", value)
  }
}

extension LocationData: DataProvider {
  var data: [DataRegister] {
    if !locationAvailable {
      return headingRegisters
    }
    return allRegisters
  }

  func enumRegisterIds(id: (String) -> Void) {
    for register in allRegisters {
      id(register.id)
    }
  }
}
