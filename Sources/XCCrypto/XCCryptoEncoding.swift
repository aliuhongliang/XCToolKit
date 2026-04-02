// XCCryptoEncoding.swift
// XCCrypto
//
// Base64 / Base64URL / Hex 编解码工具

import Foundation

public enum XCCryptoEncoding {

    // MARK: - Base64

    /// Data → Base64 字符串
    public static func base64Encode(_ data: Data) -> String {
        data.base64EncodedString()
    }

    /// Base64 字符串 → Data
    public static func base64Decode(_ string: String) -> Data? {
        // 自动补齐 padding
        var padded = string
        let remainder = padded.count % 4
        if remainder > 0 {
            padded += String(repeating: "=", count: 4 - remainder)
        }
        return Data(base64Encoded: padded)
    }

    // MARK: - Base64URL

    /// Data → URL-safe Base64（`+`→`-`, `/`→`_`，去除 `=`）
    public static func base64URLEncode(_ data: Data) -> String {
        data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    /// URL-safe Base64 → Data
    public static func base64URLDecode(_ string: String) -> Data? {
        var base64 = string
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let remainder = base64.count % 4
        if remainder > 0 {
            base64 += String(repeating: "=", count: 4 - remainder)
        }
        return Data(base64Encoded: base64)
    }

    // MARK: - Hex

    /// Data → 十六进制字符串
    public static func hexEncode(_ data: Data, uppercase: Bool = false) -> String {
        data.map { uppercase ? String(format: "%02X", $0) : String(format: "%02x", $0) }.joined()
    }

    /// 十六进制字符串 → Data
    public static func hexDecode(_ string: String) -> Data? {
        let clean = string
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "0x", with: "")
            .replacingOccurrences(of: "0X", with: "")
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
        return Data(bytes)
    }

    // MARK: - 格式互转

    /// Base64 字符串 → 十六进制字符串
    public static func base64ToHex(_ base64: String, uppercase: Bool = false) -> String? {
        guard let data = base64Decode(base64) else { return nil }
        return hexEncode(data, uppercase: uppercase)
    }

    /// 十六进制字符串 → Base64 字符串
    public static func hexToBase64(_ hex: String) -> String? {
        guard let data = hexDecode(hex) else { return nil }
        return base64Encode(data)
    }

    /// 十六进制字符串 → URL-safe Base64 字符串
    public static func hexToBase64URL(_ hex: String) -> String? {
        guard let data = hexDecode(hex) else { return nil }
        return base64URLEncode(data)
    }
}

// MARK: - String 便捷扩展

public extension String {

    // MARK: Base64
    var base64Encoded: String? {
        data(using: .utf8).map { XCCryptoEncoding.base64Encode($0) }
    }

    var base64Decoded: String? {
        guard let data = XCCryptoEncoding.base64Decode(self) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    var base64URLEncoded: String? {
        data(using: .utf8).map { XCCryptoEncoding.base64URLEncode($0) }
    }

    var base64URLDecoded: String? {
        guard let data = XCCryptoEncoding.base64URLDecode(self) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    // MARK: URL Encoding
    var urlEncoded: String? {
        addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
    }

    var urlDecoded: String? {
        removingPercentEncoding
    }

    // MARK: 哈希（CryptoKit）
    var md5String: String    { XCHash.md5(self) }
    var sha1String: String   { XCHash.sha1(self) }
    var sha256String: String { XCHash.sha256(self) }
    var sha512String: String { XCHash.sha512(self) }

    func hmacSHA256(key: String) -> String {
        XCHash.hmacSHA256(message: self, key: key)
    }

    func hmacSHA512(key: String) -> String {
        XCHash.hmacSHA512(message: self, key: key)
    }
}
