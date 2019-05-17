import Foundation


private let uploadService = URL(string: "http://cresson.the-grape.com/upload")!
private let fileNamePrefix = "data_feed-"
private let fileNameSuffix = ".log"


private extension String {
  func fileIndex() -> Int? {
    guard self.hasPrefix(fileNamePrefix) && self.hasSuffix(fileNameSuffix) else {
      return nil
    }
    let begin = self.index(self.startIndex, offsetBy: fileNamePrefix.count)
    let end = self.index(self.endIndex, offsetBy: -fileNameSuffix.count)
    return Int(self[begin..<end])
  }
}


class Logger {
  private let fileSizeLimit = 256 * 1024
  private var currentFile: FileHandle?
  private var currentFileName: URL?
  private var uploadQueue: UploadQueue?


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
    DispatchQueue.global(qos: .background).async {
      self.initUploadQueue()
    }
  }

  private func initUploadQueue() {
    objc_sync_enter(self)
    if self.uploadQueue == nil {
      self.uploadQueue = UploadQueue()
    }
    objc_sync_exit(self)
  }

  private func log(_ entry: [String: Double]) {
    guard let file = getFileHandle(), let data = try? JSONEncoder().encode(entry) else {
      return
    }
    //QUESTION: does `write` throw? documentation says it does, compiler thinks otherwise
    file.write(data)
    file.write("\n".data(using: .ascii)!)
    if file.offsetInFile >= fileSizeLimit {
      uploadQueue!.push(file: currentFileName!)
      currentFile = nil
      currentFileName = nil
    }
  }

  private func getFileHandle() -> FileHandle? {
    if currentFile != nil && currentFileName != nil && uploadQueue != nil {
      return currentFile
    }
    initUploadQueue()
    guard var url = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true) else {
      return nil
    }
    guard let files = try? FileManager.default.contentsOfDirectory(atPath: url.path) else {
      return nil
    }
    var index = 0
    for f in files {
      if let i = f.fileIndex(), i > index {
        index = i
      }
    }
    index += 1
    let fileName = fileNamePrefix + "\(index)" + fileNameSuffix
    url.appendPathComponent(fileName, isDirectory: false)
    FileManager.default.createFile(atPath: url.path, contents: nil)
    currentFile = try? FileHandle(forWritingTo: url)
    currentFileName = currentFile != nil ? url : nil
    return currentFile
  }
}


private class UploadQueue {
  private let retryInterval = 5.0
  private var fileQueue = [URL]()
  private var uploading = false
  private var suspended = false
  private var execQueue: DispatchQueue


  init() {
    execQueue = DispatchQueue(label: "UploadQueue", qos: .background)
    guard let url = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false) else {
      return
    }
    guard let files = try? FileManager.default.contentsOfDirectory(atPath: url.path) else {
      return
    }
    var toUpload = files.filter { $0.fileIndex() != nil }
    toUpload.sort { return $0.compare($1, options: .numeric) == .orderedAscending }
    fileQueue = toUpload.map() { url.appendingPathComponent($0) }
    uploadLater()
  }

  func push(file: URL) {
    execQueue.sync {
      fileQueue.append(file)
      upload()
    }
  }

  private func upload() {
    if !uploading && !suspended && !fileQueue.isEmpty {
      uploading = true
      upload(fileQueue.first!)
    }
  }

  private func uploadLater() {
    suspended = true
    execQueue.asyncAfter(deadline: .now() + retryInterval) {
      self.suspended = false
      self.upload()
    }
  }

  private func onUploadSucceed(_ file: URL) {
    execQueue.sync {
      print("UploadQueue.onUploadSucceed", file)
      uploading = false
      fileQueue.removeAll() { $0 == file }
      upload()
    }
  }

  private func onUploadError(_ file: URL, error: String) {
    execQueue.sync {
      print("UploadQueue.onUploadError", file, error)
      uploading = false
      uploadLater()
    }
  }

  private struct ServerResponse: Decodable, Encodable {
    let status: String
    let error: String?
  }

  private func upload(_ file: URL) {
    guard let payload = try? Data(contentsOf: file), let compressed = payload.compressed() else {
      onUploadError(file, error: "failed to load file") // discard file?
      return
    }
    print("UploadQueue.upload", file.path, payload.count, compressed.count)
    var request = URLRequest(url: uploadService)
    request.httpMethod = "POST"
    request.addValue("application/zlib", forHTTPHeaderField: "Content-Type")
    request.httpBody = compressed
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
      guard error == nil, let data = data, let r = try? JSONDecoder().decode(ServerResponse.self, from: data) else {
        self.onUploadError(file, error: error != nil ? error.debugDescription : "")
        return
      }
      if r.status == "OK" {
        try? FileManager.default.removeItem(at: file)
        self.onUploadSucceed(file)
      } else {
        self.onUploadError(file, error: String(data: try! JSONEncoder().encode(r), encoding: .utf8) ?? "")
      }
    }
    task.resume()
  }
}
