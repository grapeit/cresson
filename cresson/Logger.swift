import Foundation


class Logger {

  private class UploadCounter {
    private var counter = 0

    func start() {
      objc_sync_enter(self)
      counter += 1
      objc_sync_exit(self)
    }

    func startIfNotUploading() -> Bool {
      objc_sync_enter(self)
      let r = counter == 0
      if r {
        counter += 1
      }
      objc_sync_exit(self)
      return r
    }

    func finish() {
      objc_sync_enter(self)
      counter -= 1
      objc_sync_exit(self)
    }
  }


  private struct ServerResponse: Decodable, Encodable {
    let status: String
    let error: String?
  }


  private let fileSizeLimit = 512 * 1024
  private let fileNamePrefix = "data_feed-"
  private let fileNameSuffix = ".log"
  private let uploadService = URL(string: "http://cresson.the-grape.com/upload")!
  //private let uploadService = URL(string: "http://10.0.0.250:2222/upload")!
  private let uploadInterval = 60.0
  private let uploadingFilesLimit = 5
  private var currentFile: FileHandle?
  private var uploadTimer: Timer?
  private var uploadCounter = UploadCounter()


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
    guard var url = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true) else {
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
    guard uploadCounter.startIfNotUploading() else {
      return
    }
    defer { uploadCounter.finish() }
    guard let url = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false) else {
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
    // excluding last file as it is a current log
    for f in toUpload[..<min(toUpload.count - 1, uploadingFilesLimit)] {
      upload(url.appendingPathComponent(f))
    }
  }

  private func upload(_ file: URL) {
    guard let payload = try? Data(contentsOf: file), let compressed = payload.compressed() else {
      return
    }
    print("Logger.upload", file.path, payload.count, compressed.count)
    var request = URLRequest(url: uploadService)
    request.httpMethod = "POST"
    request.addValue("application/zlib", forHTTPHeaderField: "Content-Type")
    request.httpBody = compressed
    uploadCounter.start()
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
      defer { self.uploadCounter.finish() }
      guard error == nil, let data = data, let r = try? JSONDecoder().decode(ServerResponse.self, from: data) else {
        return
      }
      if r.status == "OK" {
        try? FileManager.default.removeItem(at: file)
      } else {
        print("Logger.upload", String(data: try! JSONEncoder().encode(r), encoding: .utf8) ?? "")
      }
    }
    task.resume()
  }
}
