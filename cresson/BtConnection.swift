import Foundation
import CoreBluetooth


protocol BtConnectionDelegate {
  func status(_ status: String)
}


class BtConnection: NSObject {
  private let deviceName = "cresson"
  private let serviceId = CBUUID(string: "FFE0")
  private let characteristicId = CBUUID(string: "FFE1")
  private let retryInterval = 2.0

  private var manager: CBCentralManager!
  private var peripheral: CBPeripheral!
  private var characteristic: CBCharacteristic!

  private var dataCollected = String()

  let delegate: BtConnectionDelegate

  init(_ delegate: BtConnectionDelegate) {
    self.delegate = delegate
    super.init()
    self.manager = CBCentralManager(delegate: self, queue: nil)
  }

  private func onConnectionFailed(_ error: String) {
    delegate.status("Connection failed: " + error)
    characteristic = nil
    peripheral = nil
    Timer.scheduledTimer(withTimeInterval: retryInterval, repeats: false) {_ in
      if (self.manager.state == CBManagerState.poweredOn) {
        self.delegate.status("Searching for device")
        self.manager.scanForPeripherals(withServices: [self.serviceId], options: nil)
      }
    }
  }

  private func dataIn(_ data: Data) {
    guard let newData = String(data: data, encoding: .utf8)?.replacingOccurrences(of: "\r", with: "") else {
      return
    }
    dataCollected += newData
    while let n = dataCollected.index(of: "\n") {
      delegate.status(String(dataCollected[..<n]))
      dataCollected = String(dataCollected[dataCollected.index(n, offsetBy: 1)...])
    }
  }
}


extension BtConnection: CBCentralManagerDelegate {
  func centralManagerDidUpdateState(_ central: CBCentralManager) {
    if central.state == CBManagerState.poweredOn {
      central.scanForPeripherals(withServices: [serviceId], options: nil)
      delegate.status("Searching for device")
    } else {
      self.characteristic = nil
      self.peripheral = nil
      delegate.status("Bluetooth is not available")
    }
  }

  func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
    let device = (advertisementData as NSDictionary).object(forKey: CBAdvertisementDataLocalNameKey) as? NSString
    if device?.isEqual(to: deviceName) == true {
      manager.stopScan()
      self.peripheral = peripheral
      self.peripheral.delegate = self
      delegate.status("Connecting (stage 1 of 3)")
      manager.connect(peripheral, options: nil)
    }
  }

  func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
    delegate.status("Connecting (stage 2 of 3)")
    peripheral.discoverServices([serviceId])
  }

  func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
    onConnectionFailed("Failed to connect")
  }

  func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
    onConnectionFailed("Device disconnected")
  }
}


extension BtConnection: CBPeripheralDelegate {
  func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
    for service in peripheral.services! {
      if service.uuid == serviceId {
        peripheral.discoverCharacteristics(nil, for: service)
        delegate.status("Connecting (stage 3 of 3)")
        return
      }
    }
    onConnectionFailed("Requred service is not found")
  }

  func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
    for characteristic in service.characteristics! {
      if characteristic.uuid == characteristicId {
        self.characteristic = characteristic
        peripheral.setNotifyValue(true, for: characteristic)
        delegate.status("Connected")
        return
      }
    }
    onConnectionFailed("Required characteristic not found")
  }

  func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
    if characteristic.uuid == characteristicId, let data = characteristic.value {
      dataIn(data)
    }
  }
}
