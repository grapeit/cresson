import Foundation


class Logger {
  private let fileSizeLimit = 512 * 1024
  private let fileNamePrefix = "data_feed-"
  private let fileNameSuffix = ".log"
  private let uploadInterval = 60.0
  private var currentFile: FileHandle?
  private var uploadTimer: Timer?
  private var uploading = false //TODO: need to make this one atomic?


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

  func initBackgoundUpload() {
    uploadTimer = Timer.scheduledTimer(withTimeInterval: uploadInterval, repeats: true) { _ in
      DispatchQueue.global(qos: .background).async {
        self.upload()
      }
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

  private func fileIndex(of fileName: String) -> Int? {
    guard fileName.hasPrefix(fileNamePrefix) && fileName.hasSuffix(fileNameSuffix) else {
      return nil
    }
    let begin = fileName.index(fileName.startIndex, offsetBy: fileNamePrefix.count)
    let end = fileName.index(fileName.endIndex, offsetBy: -fileNameSuffix.count)
    return Int(fileName[begin..<end])
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
      if let i = fileIndex(of: f), i > index {
        index = i
      }
    }
    index += 1
    let fileName = fileNamePrefix + "\(index)" + fileNameSuffix
    url.appendPathComponent(fileName, isDirectory: false)
    FileManager.default.createFile(atPath: url.path, contents: nil)
    currentFile = try? FileHandle(forWritingTo: url)
    return currentFile
  }

  private func upload() {
    guard !uploading else {
      return
    }
    uploading = true
    defer { uploading = false }
    guard let url = try? FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false) else {
      return
    }
    guard let files = try? FileManager.default.contentsOfDirectory(atPath: url.path) else {
      return
    }
    var toUpload = files.filter { fileIndex(of: $0) != nil }
    guard toUpload.count > 1 else {
      return
    }
    toUpload.sort { return $0.compare($1, options: .numeric) == .orderedAscending }
    for f in toUpload[..<toUpload.index(toUpload.endIndex, offsetBy: -1)] {
      let url = url.appendingPathComponent(f)
      guard upload(url) else {
        return
      }
      //TODO: uncomment when ready
      //try? FileManager.default.removeItem(at: url)
    }
  }

  private func upload(_ file: URL) -> Bool {
    guard let payload = try? Data(contentsOf: file), let compressed = payload.compressed() else {
      return false
    }
    print("Logger.upload(%@): %d => %d", file.path, payload.count, compressed.count)
    return true
  }
}
