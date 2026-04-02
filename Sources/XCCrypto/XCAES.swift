// XCAES.swift
// XCCrypto
//
// AES-GCM: CryptoKit (iOS 13+)
// AES-CBC: CommonCrypto (iOS 9+)

import Foundation
import CryptoKit
import CommonCrypto

public enum XCAES {

    // MARK: - 错误定义

    public enum AESError: Error, LocalizedError {
        case invalidKeySize        // key 长度不是 16/24/32 字节
        case invalidIVSize         // IV 长度不是 16 字节
        case encryptionFailed
        case decryptionFailed
        case invalidCombinedData   // GCM combined data 格式错误

        public var errorDescription: String? {
            switch self {
            case .invalidKeySize:      return "AES key must be 16, 24, or 32 bytes"
            case .invalidIVSize:       return "AES CBC IV must be 16 bytes"
            case .encryptionFailed:    return "AES encryption failed"
            case .decryptionFailed:    return "AES decryption failed"
            case .invalidCombinedData: return "Invalid AES-GCM combined data"
            }
        }
    }

    // MARK: - AES-GCM（推荐，CryptoKit）

    /// AES-GCM 加密
    /// - Parameters:
    ///   - data: 明文 Data
    ///   - key: 对称密钥（16/32 字节），传 nil 时自动生成 256-bit key
    /// - Returns: `(combined: Data, key: SymmetricKey)`
    ///   combined = nonce(12) + ciphertext + tag(16)，可直接存储或传输
    @discardableResult
    public static func gcmEncrypt(
        data: Data,
        key: SymmetricKey? = nil
    ) throws -> (combined: Data, key: SymmetricKey) {
        let symmetricKey = key ?? SymmetricKey(size: .bits256)
        let sealedBox = try AES.GCM.seal(data, using: symmetricKey)
        guard let combined = sealedBox.combined else {
            throw AESError.encryptionFailed
        }
        return (combined, symmetricKey)
    }

    /// AES-GCM 加密，key 为 Data
    public static func gcmEncrypt(
        data: Data,
        key: Data
    ) throws -> Data {
        let symmetricKey = SymmetricKey(data: key)
        let (combined, _) = try gcmEncrypt(data: data, key: symmetricKey)
        return combined
    }

    /// AES-GCM 解密
    /// - Parameters:
    ///   - combined: nonce + ciphertext + tag 的合并 Data
    ///   - key: 对称密钥
    /// - Returns: 明文 Data
    public static func gcmDecrypt(combined: Data, key: SymmetricKey) throws -> Data {
        let sealedBox = try AES.GCM.SealedBox(combined: combined)
        return try AES.GCM.open(sealedBox, using: key)
    }

    /// AES-GCM 解密，key 为 Data
    public static func gcmDecrypt(combined: Data, key: Data) throws -> Data {
        try gcmDecrypt(combined: combined, key: SymmetricKey(data: key))
    }

    // MARK: - AES-CBC（兼容旧服务端，CommonCrypto）

    /// AES-CBC 加密
    /// - Parameters:
    ///   - data: 明文 Data
    ///   - key: 16/24/32 字节 Data
    ///   - iv: 16 字节初始向量，传 nil 时自动生成随机 IV
    /// - Returns: `(ciphertext: Data, iv: Data)`
    public static func cbcEncrypt(
        data: Data,
        key: Data,
        iv: Data? = nil
    ) throws -> (ciphertext: Data, iv: Data) {
        let validKeySizes = [kCCKeySizeAES128, kCCKeySizeAES192, kCCKeySizeAES256]
        guard validKeySizes.contains(key.count) else { throw AESError.invalidKeySize }

        let ivData: Data
        if let provided = iv {
            guard provided.count == kCCBlockSizeAES128 else { throw AESError.invalidIVSize }
            ivData = provided
        } else {
            ivData = XCRandom.bytes(count: kCCBlockSizeAES128)
        }

        let ciphertext = try _cbcCrypt(operation: CCOperation(kCCEncrypt), data: data, key: key, iv: ivData)
        return (ciphertext, ivData)
    }

    /// AES-CBC 解密
    /// - Parameters:
    ///   - data: 密文 Data
    ///   - key: 16/24/32 字节 Data
    ///   - iv: 16 字节初始向量
    /// - Returns: 明文 Data
    public static func cbcDecrypt(data: Data, key: Data, iv: Data) throws -> Data {
        let validKeySizes = [kCCKeySizeAES128, kCCKeySizeAES192, kCCKeySizeAES256]
        guard validKeySizes.contains(key.count) else { throw AESError.invalidKeySize }
        guard iv.count == kCCBlockSizeAES128 else { throw AESError.invalidIVSize }
        return try _cbcCrypt(operation: CCOperation(kCCDecrypt), data: data, key: key, iv: iv)
    }

    // MARK: - Private CBC Helper

    private static func _cbcCrypt(
        operation: CCOperation,
        data: Data,
        key: Data,
        iv: Data
    ) throws -> Data {
        let dataLength = data.count
        let bufferSize = dataLength + kCCBlockSizeAES128
        var buffer = [UInt8](repeating: 0, count: bufferSize)
        var bytesWritten = 0

        let status = data.withUnsafeBytes { dataPtr in
            key.withUnsafeBytes { keyPtr in
                iv.withUnsafeBytes { ivPtr in
                    CCCrypt(
                        operation,
                        CCAlgorithm(kCCAlgorithmAES),
                        CCOptions(kCCOptionPKCS7Padding),
                        keyPtr.baseAddress, key.count,
                        ivPtr.baseAddress,
                        dataPtr.baseAddress, dataLength,
                        &buffer, bufferSize,
                        &bytesWritten
                    )
                }
            }
        }

        guard status == kCCSuccess else {
            throw operation == CCOperation(kCCEncrypt) ? AESError.encryptionFailed : AESError.decryptionFailed
        }
        return Data(buffer[0..<bytesWritten])
    }
}
