import Foundation


class Logger {
  private let fileSizeLimit = 512 * 1024
  private let fileNamePrefix = "data_feed-"
  private let fileNameSuffix = ".log"
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
    if file.offsetInFile >= fileSizeLimit {
      currentFile = nil
    }
  }

  private func getFileHandle() -> FileHandle? {
    if currentFile != nil {
      return currentFile
    }
    guard var url = try? FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true) else {
      return nil
    }
    guard let files = try? FileManager.default.contentsOfDirectory(atPath: url.path) else {
      return nil
    }
    var index = 0
    for f in files {
      if f.hasPrefix(fileNamePrefix) && f.hasSuffix(fileNameSuffix) {
        let indexRange = f.index(f.startIndex, offsetBy: fileNamePrefix.count)..<f.index(f.endIndex, offsetBy: -fileNameSuffix.count)
        if let i = Int(f[indexRange]), i > index {
          index = i
        }
      }
    }
    index += 1
    let fileName = fileNamePrefix + "\(index)" + fileNameSuffix
    url.appendPathComponent(fileName)
    FileManager.default.createFile(atPath: url.path, contents: nil)
    currentFile = try? FileHandle(forWritingTo: url)
    return currentFile
  }
}
