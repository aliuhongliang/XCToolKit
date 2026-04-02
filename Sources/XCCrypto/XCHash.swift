// XCHash.swift
// XCCrypto
//
// Requires: CryptoKit (iOS 13+)

import Foundation
import CryptoKit

public enum XCHash {

    // MARK: - MD5

    /// MD5 摘要，返回 Data
    public static func md5(_ data: Data) -> Data {
        Data(Insecure.MD5.hash(data: data))
    }

    /// MD5 摘要，返回十六进制字符串
    public static func md5(_ string: String) -> String {
        md5(Data(string.utf8)).hexString
    }

    // MARK: - SHA-1

    /// SHA-1 摘要，返回 Data
    public static func sha1(_ data: Data) -> Data {
        Data(Insecure.SHA1.hash(data: data))
    }

    /// SHA-1 摘要，返回十六进制字符串
    public static func sha1(_ string: String) -> String {
        sha1(Data(string.utf8)).hexString
    }

    // MARK: - SHA-256

    /// SHA-256 摘要，返回 Data
    public static func sha256(_ data: Data) -> Data {
        Data(SHA256.hash(data: data))
    }

    /// SHA-256 摘要，返回十六进制字符串
    public static func sha256(_ string: String) -> String {
        sha256(Data(string.utf8)).hexString
    }

    // MARK: - SHA-512

    /// SHA-512 摘要，返回 Data
    public static func sha512(_ data: Data) -> Data {
        Data(SHA512.hash(data: data))
    }

    /// SHA-512 摘要，返回十六进制字符串
    public static func sha512(_ string: String) -> String {
        sha512(Data(string.utf8)).hexString
    }

    // MARK: - HMAC-SHA256

    /// HMAC-SHA256，message 和 key 均为 String，返回十六进制字符串
    public static func hmacSHA256(message: String, key: String) -> String {
        hmacSHA256(message: Data(message.utf8), key: Data(key.utf8)).hexString
    }

    /// HMAC-SHA256，message 和 key 均为 Data，返回 Data
    public static func hmacSHA256(message: Data, key: Data) -> Data {
        let symmetricKey = SymmetricKey(data: key)
        let mac = HMAC<SHA256>.authenticationCode(for: message, using: symmetricKey)
        return Data(mac)
    }

    // MARK: - HMAC-SHA512

    /// HMAC-SHA512，message 和 key 均为 String，返回十六进制字符串
    public static func hmacSHA512(message: String, key: String) -> String {
        hmacSHA512(message: Data(message.utf8), key: Data(key.utf8)).hexString
    }

    /// HMAC-SHA512，message 和 key 均为 Data，返回 Data
    public static func hmacSHA512(message: Data, key: Data) -> Data {
        let symmetricKey = SymmetricKey(data: key)
        let mac = HMAC<SHA512>.authenticationCode(for: message, using: symmetricKey)
        return Data(mac)
    }
}

// MARK: - Internal Helper

private extension Data {
    var hexString: String {
        map { String(format: "%02x", $0) }.joined()
    }
}
