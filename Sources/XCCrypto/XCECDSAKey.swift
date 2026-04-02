// XCECDSAKey.swift
// XCCrypto
//
// Requires: CryptoKit (iOS 13+)
// ECDSA P-256 密钥对生成、签名、验签

import Foundation
import CryptoKit

public enum XCECDSAKey {

    // MARK: - 错误定义

    public enum ECDSAError: Error, LocalizedError {
        case invalidKeyData
        case signingFailed(String)
        case verificationFailed(String)

        public var errorDescription: String? {
            switch self {
            case .invalidKeyData:              return "Invalid ECDSA key data"
            case .signingFailed(let msg):      return "ECDSA signing failed: \(msg)"
            case .verificationFailed(let msg): return "ECDSA verification failed: \(msg)"
            }
        }
    }

    // MARK: - 密钥对

    public struct KeyPair {
        public let privateKey: P256.Signing.PrivateKey
        public let publicKey: P256.Signing.PublicKey

        /// 私钥原始 Data（32 字节）
        public var privateKeyData: Data { privateKey.rawRepresentation }

        /// 公钥未压缩 Data（65 字节，04 || x || y）
        public var publicKeyData: Data { publicKey.rawRepresentation }

        /// 私钥 Base64
        public var privateKeyBase64: String { privateKeyData.base64EncodedString() }

        /// 公钥 Base64
        public var publicKeyBase64: String { publicKeyData.base64EncodedString() }

        /// 公钥 X9.63 压缩格式 Base64（33 字节）
        @available(iOS 16.0, *)
        public var publicKeyCompressedBase64: String {
            publicKey.compressedRepresentation.base64EncodedString()
        }
    }

    // MARK: - 密钥生成

    /// 生成 P-256 密钥对
    public static func generateKeyPair() -> KeyPair {
        let privateKey = P256.Signing.PrivateKey()
        return KeyPair(privateKey: privateKey, publicKey: privateKey.publicKey)
    }

    // MARK: - 密钥导入

    /// 从原始 Data（32 字节）导入私钥
    public static func importPrivateKey(from data: Data) throws -> P256.Signing.PrivateKey {
        do {
            return try P256.Signing.PrivateKey(rawRepresentation: data)
        } catch {
            throw ECDSAError.invalidKeyData
        }
    }

    /// 从 Base64 字符串导入私钥
    public static func importPrivateKey(base64: String) throws -> P256.Signing.PrivateKey {
        guard let data = Data(base64Encoded: base64) else { throw ECDSAError.invalidKeyData }
        return try importPrivateKey(from: data)
    }

    /// 从原始 Data（65 字节未压缩 / 33 字节压缩）导入公钥
    @available(iOS 16.0, *)
    public static func importPublicKey(from data: Data) throws -> P256.Signing.PublicKey {
        do {
            return try P256.Signing.PublicKey(rawRepresentation: data)
        } catch {
            // 尝试 X9.63 压缩格式
            do {
                return try P256.Signing.PublicKey(compressedRepresentation: data)
            } catch {
                throw ECDSAError.invalidKeyData
            }
        }
    }

    /// 从 Base64 字符串导入公钥
    @available(iOS 16.0, *)
    public static func importPublicKey(base64: String) throws -> P256.Signing.PublicKey {
        guard let data = Data(base64Encoded: base64) else { throw ECDSAError.invalidKeyData }
        return try importPublicKey(from: data)
    }

    // MARK: - 签名

    /// ECDSA P-256 签名，返回 DER 编码 Data
    public static func sign(data: Data, privateKey: P256.Signing.PrivateKey) throws -> Data {
        do {
            let signature = try privateKey.signature(for: data)
            return signature.derRepresentation
        } catch {
            throw ECDSAError.signingFailed(error.localizedDescription)
        }
    }

    /// ECDSA P-256 签名，返回 Base64 字符串
    public static func sign(string: String, privateKey: P256.Signing.PrivateKey) throws -> String {
        guard let data = string.data(using: .utf8) else {
            throw ECDSAError.signingFailed("UTF-8 encoding failed")
        }
        return try sign(data: data, privateKey: privateKey).base64EncodedString()
    }

    /// ECDSA P-256 签名，返回 raw (r||s) 64 字节 Data（部分服务端使用此格式）
    public static func signRaw(data: Data, privateKey: P256.Signing.PrivateKey) throws -> Data {
        do {
            let signature = try privateKey.signature(for: data)
            return signature.rawRepresentation
        } catch {
            throw ECDSAError.signingFailed(error.localizedDescription)
        }
    }

    // MARK: - 验签

    /// ECDSA P-256 验签（DER 编码签名）
    @discardableResult
    public static func verify(
        data: Data,
        signature: Data,
        publicKey: P256.Signing.PublicKey
    ) throws -> Bool {
        do {
            let sig = try P256.Signing.ECDSASignature(derRepresentation: signature)
            return publicKey.isValidSignature(sig, for: data)
        } catch {
            throw ECDSAError.verificationFailed(error.localizedDescription)
        }
    }

    /// ECDSA P-256 验签（Base64 签名字符串）
    @discardableResult
    public static func verify(
        string: String,
        base64Signature: String,
        publicKey: P256.Signing.PublicKey
    ) throws -> Bool {
        guard let data = string.data(using: .utf8),
              let signature = Data(base64Encoded: base64Signature) else {
            throw ECDSAError.verificationFailed("Invalid input encoding")
        }
        return try verify(data: data, signature: signature, publicKey: publicKey)
    }

    /// ECDSA P-256 验签（raw r||s 64 字节签名）
    @discardableResult
    public static func verifyRaw(
        data: Data,
        rawSignature: Data,
        publicKey: P256.Signing.PublicKey
    ) throws -> Bool {
        do {
            let sig = try P256.Signing.ECDSASignature(rawRepresentation: rawSignature)
            return publicKey.isValidSignature(sig, for: data)
        } catch {
            throw ECDSAError.verificationFailed(error.localizedDescription)
        }
    }
}
