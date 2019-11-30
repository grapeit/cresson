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

  private var latitude = Register(id: "l_latitude")
  private var longitude = Register(id: "l_longitude")
  private var altitude = Register(id: "l_altitude")
  private var speed = Register(id: "l_speed")
  private var heading = Register(id: "l_heading")

  override init() {
    super.init()
    locationManager.delegate = self
    locationManager.requestWhenInUseAuthorization()
    locationManager.startUpdatingLocation()
    locationManager.startUpdatingHeading()
  }
}

extension LocationData: CLLocationManagerDelegate {
  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    guard let location = locations.last else {
      return
    }
    latitude.value = location.coordinate.latitude
    longitude.value = location.coordinate.longitude
    altitude.value = location.altitude
    speed.value = location.speed
  }

  func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
    heading.value = newHeading.trueHeading
  }
}

extension LocationData.Register: DataRegister {
  var label: String {
    return id.dropFirst(2) + ": \(value)"
  }
}

extension LocationData: DataProvider {
  var data: [DataRegister] {
    return [latitude, longitude, altitude, speed, heading]
  }

  func enumRegisterIds(id: (String) -> Void) {
    for register in data {
      id(register.id)
    }
  }
}
