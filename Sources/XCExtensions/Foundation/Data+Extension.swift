// Data+Extension.swift
// XCExtensions
//
// Requires: CryptoKit (iOS 13+), Compression framework (iOS 9+)

import Foundation
import CryptoKit
import Compression

public extension Data {

    // MARK: - 转换类

    /// 转十六进制字符串，默认小写
    func hexString(uppercase: Bool = false) -> String {
        map { uppercase ? String(format: "%02X", $0) : String(format: "%02x", $0) }.joined()
    }

    /// 转 UTF-8 字符串
    var utf8String: String? {
        String(data: self, encoding: .utf8)
    }

    /// 标准 Base64 编码字符串
    var base64EncodedString: String {
        base64EncodedString(options: [])
    }

    /// URL-safe Base64（`+`→`-`, `/`→`_`，去除 `=` padding）
    var base64URLEncodedString: String {
        base64EncodedString(options: [])
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    /// 从十六进制字符串构造 Data
    init?(hexString: String) {
        let clean = hexString.replacingOccurrences(of: " ", with: "")
        guard clean.count % 2 == 0 else { return nil }
        var bytes = [UInt8]()
        bytes.reserveCapacity(clean.count / 2)
        var index = clean.startIndex
        while index < clean.endIndex {
            let nextIndex = clean.index(index, offsetBy: 2)
            guard let byte = UInt8(clean[index..<nextIndex], radix: 16) else { return nil }
            bytes.append(byte)
            index = nextIndex
        }
        self.init(bytes)
    }

    /// 从 URL-safe Base64 字符串构造 Data
    init?(base64URLEncoded string: String) {
        var base64 = string
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let remainder = base64.count % 4
        if remainder > 0 {
            base64 += String(repeating: "=", count: 4 - remainder)
        }
        self.init(base64Encoded: base64)
    }

    // MARK: - JSON 类

    /// 解析为任意 JSON 对象
    var jsonObject: Any? {
        try? JSONSerialization.jsonObject(with: self, options: .fragmentsAllowed)
    }

    /// 解析为 `[String: Any]`
    var jsonDictionary: [String: Any]? {
        jsonObject as? [String: Any]
    }

    /// 解析为 `[[String: Any]]`
    var jsonArray: [[String: Any]]? {
        jsonObject as? [[String: Any]]
    }

    /// 泛型解码为 Decodable 模型
    func decode<T: Decodable>(_ type: T.Type, decoder: JSONDecoder = JSONDecoder()) throws -> T {
        try decoder.decode(type, from: self)
    }

    // MARK: - 哈希类（CryptoKit, iOS 13+）

    /// MD5 摘要 Data（16 字节）
    var md5Data: Data {
        Data(Insecure.MD5.hash(data: self))
    }

    /// MD5 十六进制字符串
    var md5String: String {
        md5Data.hexString()
    }

    /// SHA-1 十六进制字符串
    var sha1String: String {
        Data(Insecure.SHA1.hash(data: self)).hexString()
    }

    /// SHA-256 摘要 Data（32 字节）
    var sha256Data: Data {
        Data(SHA256.hash(data: self))
    }

    /// SHA-256 十六进制字符串
    var sha256String: String {
        sha256Data.hexString()
    }

    /// SHA-512 十六进制字符串
    var sha512String: String {
        Data(SHA512.hash(data: self)).hexString()
    }

    /// HMAC-SHA256 签名，返回十六进制字符串
    func hmacSHA256(key: Data) -> String {
        let symmetricKey = SymmetricKey(data: key)
        let mac = HMAC<SHA256>.authenticationCode(for: self, using: symmetricKey)
        return Data(mac).hexString()
    }

    /// HMAC-SHA256 签名，key 为 UTF-8 字符串
    func hmacSHA256(key: String) -> String {
        guard let keyData = key.data(using: .utf8) else { return "" }
        return hmacSHA256(key: keyData)
    }

    // MARK: - 压缩类（Compression framework, iOS 9+）

    /// 压缩，默认使用 lzfse
    func compressed(using algorithm: compression_algorithm = COMPRESSION_LZFSE) -> Data? {
        _compression(operation: COMPRESSION_STREAM_ENCODE, algorithm: algorithm)
    }

    /// 解压，默认使用 lzfse
    func decompressed(using algorithm: compression_algorithm = COMPRESSION_LZFSE) -> Data? {
        _compression(operation: COMPRESSION_STREAM_DECODE, algorithm: algorithm)
    }

//    private func _compression(
//        operation: compression_stream_operation,
//        algorithm: compression_algorithm
//    ) -> Data? {
//        guard !isEmpty else { return nil }
//        let bufferSize = 64 * 1024
//        var buffer = [UInt8](repeating: 0, count: bufferSize)
//        var stream = compression_stream()
//        guard compression_stream_init(&stream, operation, algorithm) == COMPRESSION_STATUS_OK else {
//            return nil
//        }
//        defer { compression_stream_destroy(&stream) }
//
//        var result = Data()
//        var inputData = self
//        inputData.withUnsafeBytes { rawBuffer in
//            stream.src_ptr = rawBuffer.bindMemory(to: UInt8.self).baseAddress!
//            stream.src_size = inputData.count
//        }
//
//        repeat {
//            stream.dst_ptr = &buffer
//            stream.dst_size = bufferSize
//            let flags: Int32 = stream.src_size == 0 ? Int32(COMPRESSION_STREAM_FINALIZE.rawValue) : 0
//            let status = compression_stream_process(&stream, flags)
//            guard status != COMPRESSION_STATUS_ERROR else { return }
//            let produced = bufferSize - stream.dst_size
//            result.append(contentsOf: buffer[0..<produced])
//        } while stream.src_size > 0 || stream.dst_size == 0
//
//        return result.isEmpty ? nil : result
//    }
    
    private func _compression(
        operation: compression_stream_operation,
        algorithm: compression_algorithm
    ) -> Data? {
        guard !isEmpty else { return nil }
        
        let bufferSize = 64 * 1024
        var buffer = [UInt8](repeating: 0, count: bufferSize)
        
        var stream = compression_stream(dst_ptr: UnsafeMutablePointer<UInt8>.allocate(capacity: 0), dst_size: 0, src_ptr: UnsafeMutablePointer<UInt8>.allocate(capacity: 0), src_size: 0, state: UnsafeMutablePointer<UInt8>.allocate(capacity: 0))
        
        guard compression_stream_init(&stream, operation, algorithm) == COMPRESSION_STATUS_OK else {
            return nil
        }
        defer { compression_stream_destroy(&stream) }

        var result = Data()
        
        // 2. 确保在整个处理过程中输入数据的指针都是有效的
        return self.withUnsafeBytes { rawBuffer -> Data? in
            guard let srcBase = rawBuffer.bindMemory(to: UInt8.self).baseAddress else { return nil }
            
            stream.src_ptr = srcBase
            stream.src_size = self.count
            
            while true {
                // 3. 使用 withUnsafeMutableBufferPointer 安全地传递目标缓冲区指针
                let status = buffer.withUnsafeMutableBufferPointer { bufferPtr -> compression_status in
                    stream.dst_ptr = bufferPtr.baseAddress!
                    stream.dst_size = bufferSize
                    
                    let flags = stream.src_size == 0 ? Int32(COMPRESSION_STREAM_FINALIZE.rawValue) : 0
                    return compression_stream_process(&stream, flags)
                }
                
                // 4. 处理返回状态
                guard status != COMPRESSION_STATUS_ERROR else { return nil }
                
                let produced = bufferSize - stream.dst_size
                if produced > 0 {
                    result.append(buffer, count: produced)
                }
                
                if status == COMPRESSION_STATUS_END {
                    return result.isEmpty ? nil : result
                } else if produced == 0 && stream.src_size == 0 {
                    // 防止在某些边缘情况下出现死循环
                    return result.isEmpty ? nil : result
                }
            }
        }
    }

    // MARK: - 文件 I/O 类

    /// 从文件路径安全读取
    init?(filePath: String) {
        let url = URL(fileURLWithPath: filePath)
        guard let data = try? Data(contentsOf: url) else { return nil }
        self = data
    }

    /// 写入到指定路径
    @discardableResult
    func write(toPath path: String) throws -> Bool {
        let url = URL(fileURLWithPath: path)
        try write(to: url, options: .atomic)
        return true
    }

    /// 追加写入到指定路径（文件不存在则创建）
    func append(toPath path: String) throws {
        let url = URL(fileURLWithPath: path)
        if FileManager.default.fileExists(atPath: path) {
            let handle = try FileHandle(forWritingTo: url)
            handle.seekToEndOfFile()
            handle.write(self)
            handle.closeFile()
        } else {
            try write(to: url, options: .atomic)
        }
    }

    // MARK: - 检查 / 工具类

    /// 通过 magic bytes 判断是否为 JPEG
    var isJPEG: Bool {
        count >= 3 && self[0] == 0xFF && self[1] == 0xD8 && self[2] == 0xFF
    }

    /// 通过 magic bytes 判断是否为 PNG
    var isPNG: Bool {
        count >= 8 &&
        self[0] == 0x89 && self[1] == 0x50 && self[2] == 0x4E && self[3] == 0x47 &&
        self[4] == 0x0D && self[5] == 0x0A && self[6] == 0x1A && self[7] == 0x0A
    }

    /// 通过 magic bytes 判断是否为 GIF
    var isGIF: Bool {
        count >= 6 &&
        self[0] == 0x47 && self[1] == 0x49 && self[2] == 0x46 &&
        self[3] == 0x38 && (self[4] == 0x39 || self[4] == 0x37) && self[5] == 0x61
    }

    /// 通过 magic bytes 判断是否为 WebP
    var isWebP: Bool {
        count >= 12 &&
        self[0] == 0x52 && self[1] == 0x49 && self[2] == 0x46 && self[3] == 0x46 &&
        self[8] == 0x57 && self[9] == 0x45 && self[10] == 0x42 && self[11] == 0x50
    }

    /// 根据 magic bytes 返回 MIME type
    var mimeType: String {
        if isJPEG  { return "image/jpeg" }
        if isPNG   { return "image/png" }
        if isGIF   { return "image/gif" }
        if isWebP  { return "image/webp" }
        return "application/octet-stream"
    }

    /// 格式化文件大小字符串，如 `"1.2 MB"`
    var byteCountString: String {
        ByteCountFormatter.string(fromByteCount: Int64(count), countStyle: .file)
    }

    /// 按范围切片（更直观的接口）
    func subdata(from: Int, to: Int) -> Data {
        let start = Swift.max(0, from)
        let end = Swift.min(count, to)
        guard start < end else { return Data() }
        return subdata(in: start..<end)
    }
}
