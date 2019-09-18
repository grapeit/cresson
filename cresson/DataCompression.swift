import Foundation
import Compression

extension Data {
  func compressed() -> Data? {
    var result: Data?
    withUnsafeBytes { (fromBytes: UnsafeRawBufferPointer) -> Void in
      var destSize = count > 1000 ? count / 4 : count
      var attempts = 4
      while result == nil, attempts > 0 {
        let destBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: destSize)
        let size = compression_encode_buffer(destBuffer, destSize, fromBytes.bindMemory(to: UInt8.self).baseAddress!, count, nil, Compression.COMPRESSION_ZLIB)
        if size > 0 {
          result = Data(bytes: destBuffer, count: size)
        } else {
          destSize *= 2
          attempts -= 1
        }
        destBuffer.deallocate()
      }
    }
    return result
  }
}
