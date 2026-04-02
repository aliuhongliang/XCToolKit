// XCChaChaPoly.swift
// XCCrypto
//
// Requires: CryptoKit (iOS 13+)
// ChaCha20-Poly1305 在移动端性能优于 AES（无硬件加速时）

import Foundation
import CryptoKit

public enum XCChaChaPoly {

    // MARK: - 错误定义

    public enum ChaChaError: Error, LocalizedError {
        case encryptionFailed
        case decryptionFailed
        case invalidCombinedData

        public var errorDescription: String? {
            switch self {
            case .encryptionFailed:    return "ChaCha20-Poly1305 encryption failed"
            case .decryptionFailed:    return "ChaCha20-Poly1305 decryption failed"
            case .invalidCombinedData: return "Invalid ChaCha20-Poly1305 combined data"
            }
        }
    }

    // MARK: - 加密

    /// ChaCha20-Poly1305 加密
    /// - Parameters:
    ///   - data: 明文 Data
    ///   - key: 对称密钥，传 nil 时自动生成 256-bit key
    /// - Returns: `(combined: Data, key: SymmetricKey)`
    ///   combined = nonce(12) + ciphertext + tag(16)
    @discardableResult
    public static func encrypt(
        data: Data,
        key: SymmetricKey? = nil
    ) throws -> (combined: Data, key: SymmetricKey) {
        let symmetricKey = key ?? SymmetricKey(size: .bits256)
        let sealedBox = try ChaChaPoly.seal(data, using: symmetricKey)
        return (sealedBox.combined, symmetricKey)
    }

    /// ChaCha20-Poly1305 加密，key 为 Data（32 字节）
    public static func encrypt(data: Data, key: Data) throws -> Data {
        let symmetricKey = SymmetricKey(data: key)
        let (combined, _) = try encrypt(data: data, key: symmetricKey)
        return combined
    }

    /// ChaCha20-Poly1305 加密字符串
    /// - Returns: Base64 编码的 combined Data 字符串
    public static func encrypt(string: String, key: SymmetricKey) throws -> String {
        guard let data = string.data(using: .utf8) else {
            throw ChaChaError.encryptionFailed
        }
        let (combined, _) = try encrypt(data: data, key: key)
        return combined.base64EncodedString()
    }

    // MARK: - 解密

    /// ChaCha20-Poly1305 解密
    /// - Parameters:
    ///   - combined: nonce + ciphertext + tag 的合并 Data
    ///   - key: 对称密钥
    /// - Returns: 明文 Data
    public static func decrypt(combined: Data, key: SymmetricKey) throws -> Data {
        let sealedBox = try ChaChaPoly.SealedBox(combined: combined)
        return try ChaChaPoly.open(sealedBox, using: key)
    }

    /// ChaCha20-Poly1305 解密，key 为 Data（32 字节）
    public static func decrypt(combined: Data, key: Data) throws -> Data {
        try decrypt(combined: combined, key: SymmetricKey(data: key))
    }

    /// ChaCha20-Poly1305 解密为字符串
    /// - Parameter base64Combined: Base64 编码的 combined Data 字符串
    public static func decrypt(base64Combined: String, key: SymmetricKey) throws -> String {
        guard let combined = Data(base64Encoded: base64Combined) else {
            throw ChaChaError.invalidCombinedData
        }
        let plainData = try decrypt(combined: combined, key: key)
        guard let string = String(data: plainData, encoding: .utf8) else {
            throw ChaChaError.decryptionFailed
        }
        return string
    }

    // MARK: - 密钥工具

    /// 生成随机 256-bit SymmetricKey
    public static func generateKey() -> SymmetricKey {
        SymmetricKey(size: .bits256)
    }

    /// 将 SymmetricKey 导出为 Data（用于存储/传输）
    public static func exportKey(_ key: SymmetricKey) -> Data {
        key.withUnsafeBytes { Data($0) }
    }

    /// 从 Data 恢复 SymmetricKey
    public static func importKey(from data: Data) -> SymmetricKey {
        SymmetricKey(data: data)
    }
}
