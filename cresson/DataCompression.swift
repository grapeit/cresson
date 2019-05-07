import Foundation
import Compression


extension Data {
  func compressed() -> Data? {
    var r: Data?
    withUnsafeBytes { (fromBytes: UnsafeRawBufferPointer) -> Void in
      var destSize = count > 1000 ? count / 4 : count
      var attempts = 4
      while r == nil, attempts > 0 {
        let destBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: destSize)
        let s = compression_encode_buffer(destBuffer, destSize, fromBytes.bindMemory(to: UInt8.self).baseAddress!, count, nil, Compression.COMPRESSION_ZLIB)
        if s > 0 {
          r = Data(bytes: destBuffer, count: s)
        } else {
          destSize *= 2
          attempts -= 1
        }
        destBuffer.deallocate()
      }
    }
    return r
  }
}
