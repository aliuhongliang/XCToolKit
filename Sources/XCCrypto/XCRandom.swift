// XCRandom.swift
// XCCrypto
//
// Requires: CryptoKit (iOS 13+), Security framework

import Foundation
import CryptoKit
import Security

public enum XCRandom {

    // MARK: - 随机字节

    /// 生成密码学安全的随机 Data
    public static func bytes(count: Int) -> Data {
        var bytes = [UInt8](repeating: 0, count: count)
        _ = SecRandomCopyBytes(kSecRandomDefault, count, &bytes)
        return Data(bytes)
    }

    // MARK: - 随机字符串

    public enum Charset: String {
        case numeric      = "0123456789"
        case lowercase    = "abcdefghijklmnopqrstuvwxyz"
        case uppercase    = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        case alphabetic   = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
        case alphanumeric = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        case hex          = "0123456789abcdef"
        case base62       = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    }

    /// 生成指定长度的随机字符串
    /// - Parameters:
    ///   - length: 字符串长度
    ///   - charset: 字符集，默认 alphanumeric
    public static func string(length: Int, charset: Charset = .alphanumeric) -> String {
        let chars = Array(charset.rawValue)
        return string(length: length, from: chars)
    }

    /// 从自定义字符集生成随机字符串
    public static func string(length: Int, from charset: String) -> String {
        string(length: length, from: Array(charset))
    }

    private static func string(length: Int, from chars: [Character]) -> String {
        guard !chars.isEmpty, length > 0 else { return "" }
        return String((0..<length).map { _ in chars[int(in: 0..<chars.count)] })
    }

    // MARK: - 随机整数

    /// 安全随机整数，范围 [range.lowerBound, range.upperBound)
    public static func int(in range: Range<Int>) -> Int {
        let count = range.upperBound - range.lowerBound
        guard count > 0 else { return range.lowerBound }
        var random: UInt32 = 0
        _ = SecRandomCopyBytes(kSecRandomDefault, 4, &random)
        return range.lowerBound + Int(random % UInt32(count))
    }

    /// 安全随机整数，范围 [range.lowerBound, range.upperBound]
    public static func int(in range: ClosedRange<Int>) -> Int {
        int(in: range.lowerBound..<(range.upperBound + 1))
    }

    // MARK: - UUID

    /// 密码学安全的 UUID 字符串（基于随机字节，符合 RFC 4122 v4）
    public static func uuid() -> String {
        var bytes = bytes(count: 16)
        // 设置 version = 4
        bytes[6] = (bytes[6] & 0x0F) | 0x40
        // 设置 variant = 0b10xx xxxx
        bytes[8] = (bytes[8] & 0x3F) | 0x80
        return String(format: "%02X%02X%02X%02X-%02X%02X-%02X%02X-%02X%02X-%02X%02X%02X%02X%02X%02X",
            bytes[0], bytes[1], bytes[2], bytes[3],
            bytes[4], bytes[5],
            bytes[6], bytes[7],
            bytes[8], bytes[9],
            bytes[10], bytes[11], bytes[12], bytes[13], bytes[14], bytes[15]
        )
    }

    // MARK: - AES 密钥生成

    /// 生成 AES SymmetricKey
    /// - Parameter bits: 128、192 或 256
    public static func aesKey(bits: Int = 256) -> SymmetricKey {
        switch bits {
        case 128: return SymmetricKey(size: .bits128)
        case 192: return SymmetricKey(size: .init(bitCount: 192))
        default:  return SymmetricKey(size: .bits256)
        }
    }

    /// 生成 AES 密钥并导出为 Data
    public static func aesKeyData(bits: Int = 256) -> Data {
        let key = aesKey(bits: bits)
        return key.withUnsafeBytes { Data($0) }
    }

    // MARK: - PIN / OTP

    /// 生成数字 PIN 码，默认 6 位
    public static func pin(length: Int = 6) -> String {
        string(length: length, charset: .numeric)
    }

    /// 生成 OTP token（alphanumeric，默认 32 位）
    public static func token(length: Int = 32) -> String {
        string(length: length, charset: .alphanumeric)
    }
}
