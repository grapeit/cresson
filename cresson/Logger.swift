import Foundation


class Logger {
  private var currentFile: FileHandle?


  func log(_ registers: [BikeData.Register]) {
    var entry = [String: Double]()
    for register in registers {
      if let key = String(reflecting: register.id).components(separatedBy: ".").last {
        entry[key] = register.normalize()
      }
    }
    entry["ts"] = Date.timeIntervalSinceReferenceDate + Date.timeIntervalBetween1970AndReferenceDate
    DispatchQueue.global(qos: .utility).async {
      objc_sync_enter(self)
      self.log(entry)
      objc_sync_exit(self)
    }
  }

  private func log(_ entry: [String: Double]) {
    guard let file = getFileHandle(), let data = try? JSONEncoder().encode(entry) else {
      return
    }
    //QUESTION: does `write` throw? documentation says it does, compiler thinks otherwise
    file.write(data)
    file.write("\n".data(using: .ascii)!)
  }

  private func getFileHandle() -> FileHandle? {
    if currentFile != nil {
      return currentFile
    }
    let fm = FileManager.default
    guard var url = try? fm.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true) else {
      return nil
    }
    url.appendPathComponent("data_feed.log")
    if !fm.fileExists(atPath: url.path) {
      fm.createFile(atPath: url.path, contents: nil)
    }
    currentFile = try? FileHandle(forWritingTo: url)
    guard currentFile != nil else {
      return nil
    }
    return currentFile
  }
}
