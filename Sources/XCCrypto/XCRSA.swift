// XCRSA.swift
// XCCrypto
//
// Requires: Security framework
// RSA 加解密 / 签名验签，使用 SecKey API

import Foundation
import Security

public enum XCRSA {

    // MARK: - 错误定义

    public enum RSAError: Error, LocalizedError {
        case keyGenerationFailed
        case invalidKeyData
        case invalidKeyFormat
        case encryptionFailed(String)
        case decryptionFailed(String)
        case signingFailed(String)
        case verificationFailed(String)
        case exportFailed

        public var errorDescription: String? {
            switch self {
            case .keyGenerationFailed:         return "RSA key generation failed"
            case .invalidKeyData:              return "Invalid RSA key data"
            case .invalidKeyFormat:            return "Invalid RSA key format"
            case .encryptionFailed(let msg):   return "RSA encryption failed: \(msg)"
            case .decryptionFailed(let msg):   return "RSA decryption failed: \(msg)"
            case .signingFailed(let msg):      return "RSA signing failed: \(msg)"
            case .verificationFailed(let msg): return "RSA verification failed: \(msg)"
            case .exportFailed:                return "RSA key export failed"
            }
        }
    }

    // MARK: - 密钥对

    public struct KeyPair {
        public let privateKey: SecKey
        public let publicKey: SecKey
    }

    /// 生成 RSA 密钥对
    /// - Parameter bits: 密钥位数，推荐 2048 或 4096
    public static func generateKeyPair(bits: Int = 2048) throws -> KeyPair {
        let attributes: [String: Any] = [
            kSecAttrKeyType as String:       kSecAttrKeyTypeRSA,
            kSecAttrKeySizeInBits as String: bits,
        ]
        var error: Unmanaged<CFError>?
        guard let privateKey = SecKeyCreateRandomKey(attributes as CFDictionary, &error),
              let publicKey = SecKeyCopyPublicKey(privateKey) else {
            throw RSAError.keyGenerationFailed
        }
        return KeyPair(privateKey: privateKey, publicKey: publicKey)
    }

    // MARK: - 密钥导入 / 导出

    /// 将 SecKey 导出为 DER Data
    public static func exportKey(_ key: SecKey) throws -> Data {
        var error: Unmanaged<CFError>?
        guard let data = SecKeyCopyExternalRepresentation(key, &error) as Data? else {
            throw RSAError.exportFailed
        }
        return data
    }

    /// 将 SecKey 导出为 Base64 字符串
    public static func exportKeyBase64(_ key: SecKey) throws -> String {
        try exportKey(key).base64EncodedString()
    }

    /// 从 DER Data 导入公钥
    public static func importPublicKey(from data: Data) throws -> SecKey {
        let attributes: [String: Any] = [
            kSecAttrKeyType as String:  kSecAttrKeyTypeRSA,
            kSecAttrKeyClass as String: kSecAttrKeyClassPublic,
        ]
        var error: Unmanaged<CFError>?
        guard let key = SecKeyCreateWithData(data as CFData, attributes as CFDictionary, &error) else {
            throw RSAError.invalidKeyData
        }
        return key
    }

    /// 从 Base64 字符串导入公钥
    public static func importPublicKey(base64: String) throws -> SecKey {
        guard let data = Data(base64Encoded: base64) else { throw RSAError.invalidKeyFormat }
        return try importPublicKey(from: data)
    }

    /// 从 DER Data 导入私钥
    public static func importPrivateKey(from data: Data) throws -> SecKey {
        let attributes: [String: Any] = [
            kSecAttrKeyType as String:  kSecAttrKeyTypeRSA,
            kSecAttrKeyClass as String: kSecAttrKeyClassPrivate,
        ]
        var error: Unmanaged<CFError>?
        guard let key = SecKeyCreateWithData(data as CFData, attributes as CFDictionary, &error) else {
            throw RSAError.invalidKeyData
        }
        return key
    }

    /// 从 Base64 字符串导入私钥
    public static func importPrivateKey(base64: String) throws -> SecKey {
        guard let data = Data(base64Encoded: base64) else { throw RSAError.invalidKeyFormat }
        return try importPrivateKey(from: data)
    }

    // MARK: - 加密 / 解密（OAEP padding）

    /// RSA 公钥加密（RSAES-OAEP-SHA256）
    public static func encrypt(data: Data, publicKey: SecKey) throws -> Data {
        var error: Unmanaged<CFError>?
        guard let encrypted = SecKeyCreateEncryptedData(
            publicKey,
            .rsaEncryptionOAEPSHA256,
            data as CFData,
            &error
        ) as Data? else {
            let msg = error?.takeRetainedValue().localizedDescription ?? "unknown"
            throw RSAError.encryptionFailed(msg)
        }
        return encrypted
    }

    /// RSA 公钥加密，返回 Base64 字符串
    public static func encrypt(string: String, publicKey: SecKey) throws -> String {
        guard let data = string.data(using: .utf8) else { throw RSAError.encryptionFailed("UTF-8 encoding failed") }
        return try encrypt(data: data, publicKey: publicKey).base64EncodedString()
    }

    /// RSA 私钥解密（RSAES-OAEP-SHA256）
    public static func decrypt(data: Data, privateKey: SecKey) throws -> Data {
        var error: Unmanaged<CFError>?
        guard let decrypted = SecKeyCreateDecryptedData(
            privateKey,
            .rsaEncryptionOAEPSHA256,
            data as CFData,
            &error
        ) as Data? else {
            let msg = error?.takeRetainedValue().localizedDescription ?? "unknown"
            throw RSAError.decryptionFailed(msg)
        }
        return decrypted
    }

    /// RSA 私钥解密，返回 UTF-8 字符串
    public static func decryptToString(data: Data, privateKey: SecKey) throws -> String {
        let plain = try decrypt(data: data, privateKey: privateKey)
        guard let string = String(data: plain, encoding: .utf8) else {
            throw RSAError.decryptionFailed("UTF-8 decoding failed")
        }
        return string
    }

    // MARK: - 签名 / 验签（SHA256withRSA）

    /// RSA 私钥签名（RSASSA-PKCS1-v1_5-SHA256）
    public static func sign(data: Data, privateKey: SecKey) throws -> Data {
        var error: Unmanaged<CFError>?
        guard let signature = SecKeyCreateSignature(
            privateKey,
            .rsaSignatureMessagePKCS1v15SHA256,
            data as CFData,
            &error
        ) as Data? else {
            let msg = error?.takeRetainedValue().localizedDescription ?? "unknown"
            throw RSAError.signingFailed(msg)
        }
        return signature
    }

    /// RSA 私钥签名，返回 Base64 字符串
    public static func sign(string: String, privateKey: SecKey) throws -> String {
        guard let data = string.data(using: .utf8) else { throw RSAError.signingFailed("UTF-8 encoding failed") }
        return try sign(data: data, privateKey: privateKey).base64EncodedString()
    }

    /// RSA 公钥验签
    /// - Returns: 验签是否通过
    @discardableResult
    public static func verify(data: Data, signature: Data, publicKey: SecKey) throws -> Bool {
        var error: Unmanaged<CFError>?
        let result = SecKeyVerifySignature(
            publicKey,
            .rsaSignatureMessagePKCS1v15SHA256,
            data as CFData,
            signature as CFData,
            &error
        )
        if let err = error {
            throw RSAError.verificationFailed(err.takeRetainedValue().localizedDescription)
        }
        return result
    }

    /// RSA 公钥验签（Base64 签名字符串版本）
    @discardableResult
    public static func verify(string: String, base64Signature: String, publicKey: SecKey) throws -> Bool {
        guard let data = string.data(using: .utf8),
              let signature = Data(base64Encoded: base64Signature) else {
            throw RSAError.verificationFailed("Invalid input encoding")
        }
        return try verify(data: data, signature: signature, publicKey: publicKey)
    }
}
