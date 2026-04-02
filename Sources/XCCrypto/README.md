# XCCrypto 使用文档

> **模块**：`XCCrypto`
> **最低系统要求**：iOS 13+
> **框架依赖**：CryptoKit · CommonCrypto · Security
> **无第三方依赖**

---

## 目录

1. [XCHash — 哈希与 HMAC](#1-xchash--哈希与-hmac)
2. [XCAES — AES 对称加密](#2-xcaes--aes-对称加密)
3. [XCChaChaPoly — ChaCha20-Poly1305 加密](#3-xccchachapoly--chacha20-poly1305-加密)
4. [XCRSA — RSA 非对称加密与签名](#4-xcrsa--rsa-非对称加密与签名)
5. [XCECDSAKey — ECDSA P-256 签名](#5-xcecdsakey--ecdsa-p-256-签名)
6. [XCRandom — 安全随机数生成](#6-xcrandom--安全随机数生成)
7. [XCCryptoEncoding — 编解码工具](#7-xccryptoencoding--编解码工具)
8. [String 扩展 — 哈希与编解码快捷调用](#8-string-扩展--哈希与编解码快捷调用)
9. [算法选型指南](#9-算法选型指南)
10. [错误处理](#10-错误处理)

---

## 1. XCHash — 哈希与 HMAC

> 底层使用 **CryptoKit**，所有方法均为纯函数，线程安全。

### 1.1 MD5

```swift
// 字符串 → 十六进制字符串
let hash = XCHash.md5("hello")
// "5d41402abc4b2a76b9719d911017c592"

// Data → Data（16 字节）
let data = XCHash.md5(Data("hello".utf8))
```

> ⚠️ MD5 已不具备密码学安全性，仅用于文件校验、缓存 key 等非安全场景。

### 1.2 SHA-1

```swift
let hash = XCHash.sha1("hello")
// "aaf4c61ddcc5e8a2dabede0f3b482cd9aea9434d"

let data = XCHash.sha1(Data("hello".utf8))
```

> ⚠️ SHA-1 同样已被认为不安全，优先使用 SHA-256。

### 1.3 SHA-256

```swift
// 字符串 → 十六进制字符串
let hash = XCHash.sha256("hello")
// "2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824"

// Data → Data（32 字节）
let data = XCHash.sha256(someData)

// 文件完整性校验示例
func verifyFileIntegrity(fileURL: URL, expectedHash: String) -> Bool {
    guard let data = try? Data(contentsOf: fileURL) else { return false }
    return XCHash.sha256(data).map { String(format: "%02x", $0) }.joined() == expectedHash
}
```

### 1.4 SHA-512

```swift
let hash = XCHash.sha512("hello")
let data = XCHash.sha512(someData)
```

### 1.5 HMAC-SHA256（接口签名常用）

```swift
// String 版本
let signature = XCHash.hmacSHA256(message: "timestamp=1234567890&nonce=abc", key: "your_secret_key")

// Data 版本（返回 Data）
let sigData = XCHash.hmacSHA256(
    message: Data("body content".utf8),
    key: Data("secret".utf8)
)
```

**接口请求签名示例：**

```swift
func signRequest(params: [String: String], secretKey: String) -> String {
    // 参数按 key 排序拼接
    let message = params.sorted { $0.key < $1.key }
        .map { "\($0.key)=\($0.value)" }
        .joined(separator: "&")
    return XCHash.hmacSHA256(message: message, key: secretKey)
}
```

### 1.6 HMAC-SHA512

```swift
let signature = XCHash.hmacSHA512(message: "payload", key: "secret")
let sigData = XCHash.hmacSHA512(message: someData, key: keyData)
```

---

## 2. XCAES — AES 对称加密

### 2.1 AES-GCM（推荐）

> 使用 **CryptoKit**，提供加密 + 完整性认证（AEAD），是现代应用的首选方案。
> `combined` 格式 = nonce(12 字节) + ciphertext + tag(16 字节)，可直接存储或传输。

#### 自动生成密钥加密

```swift
do {
    // key 传 nil，自动生成 256-bit 随机密钥
    let (combined, key) = try XCAES.gcmEncrypt(data: plainData)
    
    // 导出密钥（用于后续解密，需安全存储）
    let keyData = key.withUnsafeBytes { Data($0) }
    
    print("密文长度：\(combined.count) 字节")
} catch {
    print("加密失败：\(error.localizedDescription)")
}
```

#### 使用指定密钥加密

```swift
// 使用 SymmetricKey
let key = XCRandom.aesKey(bits: 256)

do {
    let (combined, _) = try XCAES.gcmEncrypt(data: plainData, key: key)
    
    // 解密
    let decrypted = try XCAES.gcmDecrypt(combined: combined, key: key)
    let plainText = String(data: decrypted, encoding: .utf8)
} catch {
    print("错误：\(error.localizedDescription)")
}
```

#### 使用 Data 类型密钥

```swift
// 适合从服务端或 Keychain 取回密钥的场景
let keyData: Data = ... // 32 字节

do {
    let combined = try XCAES.gcmEncrypt(data: plainData, key: keyData)
    let decrypted = try XCAES.gcmDecrypt(combined: combined, key: keyData)
} catch {
    print("错误：\(error.localizedDescription)")
}
```

#### 加密字符串完整示例

```swift
func encryptUserData(_ text: String, keyData: Data) throws -> String {
    guard let plainData = text.data(using: .utf8) else {
        throw XCAES.AESError.encryptionFailed
    }
    let combined = try XCAES.gcmEncrypt(data: plainData, key: keyData)
    return combined.base64EncodedString()
}

func decryptUserData(_ base64: String, keyData: Data) throws -> String {
    guard let combined = Data(base64Encoded: base64) else {
        throw XCAES.AESError.invalidCombinedData
    }
    let plainData = try XCAES.gcmDecrypt(combined: combined, key: keyData)
    guard let text = String(data: plainData, encoding: .utf8) else {
        throw XCAES.AESError.decryptionFailed
    }
    return text
}
```

---

### 2.2 AES-CBC（兼容旧服务端）

> 使用 **CommonCrypto**，PKCS7 填充。
> 适合对接要求 AES-CBC 的旧服务端或第三方 SDK。

#### 基础用法

```swift
let key = Data("0123456789abcdef".utf8) // 16 字节 = AES-128
                                         // 24 字节 = AES-192
                                         // 32 字节 = AES-256

do {
    // iv 传 nil，自动生成随机 IV（推荐）
    let (ciphertext, iv) = try XCAES.cbcEncrypt(data: plainData, key: key)
    
    // 传输时通常将 iv + ciphertext 拼接或分开传递
    let ivBase64 = iv.base64EncodedString()
    let ciphertextBase64 = ciphertext.base64EncodedString()
    
    // 解密
    let decrypted = try XCAES.cbcDecrypt(data: ciphertext, key: key, iv: iv)
} catch {
    print("错误：\(error.localizedDescription)")
}
```

#### 使用固定 IV（兼容特定服务端）

```swift
let key  = Data("your-16-byte-key".utf8)
let iv   = Data("your-16-byte-iv!".utf8) // 必须 16 字节

do {
    let (ciphertext, _) = try XCAES.cbcEncrypt(data: plainData, key: key, iv: iv)
    let decrypted = try XCAES.cbcDecrypt(data: ciphertext, key: key, iv: iv)
} catch {
    print("错误：\(error.localizedDescription)")
}
```

> ⚠️ 不建议使用固定 IV，每次加密应使用随机 IV 并随密文一起传递。

#### AES-CBC 与服务端对接典型流程

```swift
// 服务端要求：AES-128-CBC，IV 拼接在密文头部，整体 Base64 编码
func encryptForServer(text: String, hexKey: String) throws -> String {
    guard let keyData = XCCryptoEncoding.hexDecode(hexKey) else {
        throw XCAES.AESError.invalidKeySize
    }
    guard let plainData = text.data(using: .utf8) else {
        throw XCAES.AESError.encryptionFailed
    }
    let (ciphertext, iv) = try XCAES.cbcEncrypt(data: plainData, key: keyData)
    
    // IV(16) + ciphertext 拼接后 Base64
    var combined = iv
    combined.append(ciphertext)
    return combined.base64EncodedString()
}

func decryptFromServer(base64: String, hexKey: String) throws -> String {
    guard let keyData = XCCryptoEncoding.hexDecode(hexKey),
          let combined = Data(base64Encoded: base64),
          combined.count > 16 else {
        throw XCAES.AESError.decryptionFailed
    }
    let iv = combined.subdata(in: 0..<16)
    let ciphertext = combined.subdata(in: 16..<combined.count)
    let plainData = try XCAES.cbcDecrypt(data: ciphertext, key: keyData, iv: iv)
    guard let text = String(data: plainData, encoding: .utf8) else {
        throw XCAES.AESError.decryptionFailed
    }
    return text
}
```

---

### 2.3 AES 错误类型

```swift
XCAES.AESError.invalidKeySize      // key 不是 16/24/32 字节
XCAES.AESError.invalidIVSize       // CBC 的 IV 不是 16 字节
XCAES.AESError.encryptionFailed    // 加密过程失败
XCAES.AESError.decryptionFailed    // 解密失败（key/iv 错误或数据被篡改）
XCAES.AESError.invalidCombinedData // GCM combined data 格式不正确
```

---

## 3. XCChaChaPoly — ChaCha20-Poly1305 加密

> 使用 **CryptoKit**，在没有 AES 硬件加速的设备上性能优于 AES-GCM。
> 同样是 AEAD 算法，combined 格式 = nonce(12) + ciphertext + tag(16)。

### 3.1 基础加密 / 解密

```swift
// 自动生成密钥
do {
    let (combined, key) = try XCChaChaPoly.encrypt(data: plainData)
    let decrypted = try XCChaChaPoly.decrypt(combined: combined, key: key)
} catch {
    print("错误：\(error.localizedDescription)")
}
```

### 3.2 使用指定密钥（Data 类型）

```swift
let keyData = XCRandom.bytes(count: 32) // 必须 32 字节

do {
    let combined = try XCChaChaPoly.encrypt(data: plainData, key: keyData)
    let decrypted = try XCChaChaPoly.decrypt(combined: combined, key: keyData)
} catch {
    print("错误：\(error.localizedDescription)")
}
```

### 3.3 加密字符串（返回 Base64）

```swift
let key = XCChaChaPoly.generateKey()

do {
    // 加密 → Base64 字符串
    let base64Encrypted = try XCChaChaPoly.encrypt(string: "敏感信息", key: key)
    
    // 从 Base64 解密
    let plainText = try XCChaChaPoly.decrypt(base64Combined: base64Encrypted, key: key)
    print(plainText) // "敏感信息"
} catch {
    print("错误：\(error.localizedDescription)")
}
```

### 3.4 密钥管理

```swift
// 生成密钥
let key = XCChaChaPoly.generateKey()

// 导出为 Data（存入 Keychain 或传输）
let keyData = XCChaChaPoly.exportKey(key)

// 从 Data 恢复
let restoredKey = XCChaChaPoly.importKey(from: keyData)
```

### 3.5 错误类型

```swift
XCChaChaPoly.ChaChaError.encryptionFailed
XCChaChaPoly.ChaChaError.decryptionFailed
XCChaChaPoly.ChaChaError.invalidCombinedData
```

---

## 4. XCRSA — RSA 非对称加密与签名

> 使用 **Security framework**，支持密钥生成、导入导出、OAEP 加密、PKCS1v15 签名。

### 4.1 生成密钥对

```swift
do {
    // 默认 2048 位，生产环境推荐 2048 或 4096
    let keyPair = try XCRSA.generateKeyPair(bits: 2048)
    
    // 导出公钥（发送给对方或服务端）
    let publicKeyBase64 = try XCRSA.exportKeyBase64(keyPair.publicKey)
    
    // 导出私钥（安全存储，勿传输）
    let privateKeyBase64 = try XCRSA.exportKeyBase64(keyPair.privateKey)
    
    print("公钥：\(publicKeyBase64)")
} catch {
    print("密钥生成失败：\(error.localizedDescription)")
}
```

### 4.2 导入已有密钥

```swift
// 从 Base64 字符串导入
do {
    let publicKey  = try XCRSA.importPublicKey(base64: publicKeyBase64String)
    let privateKey = try XCRSA.importPrivateKey(base64: privateKeyBase64String)
} catch {
    print("密钥导入失败：\(error.localizedDescription)")
}

// 从 DER Data 导入
do {
    let publicKey  = try XCRSA.importPublicKey(from: derData)
    let privateKey = try XCRSA.importPrivateKey(from: derData)
} catch { ... }
```

### 4.3 加密 / 解密（RSAES-OAEP-SHA256）

```swift
do {
    let publicKey = try XCRSA.importPublicKey(base64: serverPublicKey)
    
    // 加密 Data
    let encryptedData = try XCRSA.encrypt(data: plainData, publicKey: publicKey)
    
    // 加密字符串，返回 Base64
    let encryptedBase64 = try XCRSA.encrypt(string: "my_password", publicKey: publicKey)
    
    // 解密
    let privateKey = try XCRSA.importPrivateKey(base64: myPrivateKey)
    let decryptedData = try XCRSA.decrypt(data: encryptedData, privateKey: privateKey)
    let decryptedText = try XCRSA.decryptToString(data: encryptedData, privateKey: privateKey)
} catch {
    print("RSA 操作失败：\(error.localizedDescription)")
}
```

> ⚠️ RSA 加密的数据长度有限制。
> 2048 位密钥 + OAEP-SHA256 最大明文 = (2048/8) - 2*32 - 2 = **190 字节**。
> 超长数据应先用 AES-GCM 加密，再用 RSA 加密 AES 密钥（混合加密）。

#### 混合加密示例

```swift
func hybridEncrypt(data: Data, rsaPublicKey: SecKey) throws -> (aesKeyEncrypted: Data, combined: Data) {
    // 1. 生成随机 AES-256 密钥
    let (combined, aesKey) = try XCAES.gcmEncrypt(data: data)
    
    // 2. 用 RSA 公钥加密 AES 密钥
    let aesKeyData = aesKey.withUnsafeBytes { Data($0) }
    let encryptedAESKey = try XCRSA.encrypt(data: aesKeyData, publicKey: rsaPublicKey)
    
    return (encryptedAESKey, combined)
}

func hybridDecrypt(aesKeyEncrypted: Data, combined: Data, rsaPrivateKey: SecKey) throws -> Data {
    // 1. 用 RSA 私钥解密 AES 密钥
    let aesKeyData = try XCRSA.decrypt(data: aesKeyEncrypted, privateKey: rsaPrivateKey)
    
    // 2. 用 AES-GCM 解密数据
    return try XCAES.gcmDecrypt(combined: combined, key: aesKeyData)
}
```

### 4.4 签名 / 验签（RSASSA-PKCS1-v1_5-SHA256）

```swift
do {
    let keyPair = try XCRSA.generateKeyPair()
    
    // 签名 Data，返回 Data
    let signature = try XCRSA.sign(data: payloadData, privateKey: keyPair.privateKey)
    
    // 签名字符串，返回 Base64
    let signatureBase64 = try XCRSA.sign(string: "payload", privateKey: keyPair.privateKey)
    
    // 验签
    let isValid = try XCRSA.verify(data: payloadData, signature: signature, publicKey: keyPair.publicKey)
    print("验签结果：\(isValid)")
    
    // 验签（Base64 签名版本）
    let isValid2 = try XCRSA.verify(
        string: "payload",
        base64Signature: signatureBase64,
        publicKey: keyPair.publicKey
    )
} catch {
    print("RSA 签名失败：\(error.localizedDescription)")
}
```

### 4.5 错误类型

```swift
XCRSA.RSAError.keyGenerationFailed
XCRSA.RSAError.invalidKeyData
XCRSA.RSAError.invalidKeyFormat
XCRSA.RSAError.encryptionFailed("原因描述")
XCRSA.RSAError.decryptionFailed("原因描述")
XCRSA.RSAError.signingFailed("原因描述")
XCRSA.RSAError.verificationFailed("原因描述")
XCRSA.RSAError.exportFailed
```

---

## 5. XCECDSAKey — ECDSA P-256 签名

> 使用 **CryptoKit P256**，比 RSA 密钥更短、签名更快，适合移动端。

### 5.1 生成密钥对

```swift
let keyPair = XCECDSAKey.generateKeyPair()

// 导出（用于存储）
print("私钥 Base64：\(keyPair.privateKeyBase64)")   // 32 字节 → ~44 字符
print("公钥 Base64：\(keyPair.publicKeyBase64)")    // 65 字节未压缩
print("公钥压缩 Base64：\(keyPair.publicKeyCompressedBase64)") // 33 字节压缩
```

### 5.2 导入密钥

```swift
do {
    // 导入私钥
    let privateKey = try XCECDSAKey.importPrivateKey(base64: privateKeyBase64)
    
    // 导入公钥（自动识别未压缩 65 字节 / 压缩 33 字节）
    let publicKey = try XCECDSAKey.importPublicKey(base64: publicKeyBase64)
} catch {
    print("密钥导入失败：\(error.localizedDescription)")
}
```

### 5.3 签名

```swift
do {
    let keyPair = XCECDSAKey.generateKeyPair()
    
    // DER 编码签名（标准格式，推荐）
    let signature = try XCECDSAKey.sign(data: payloadData, privateKey: keyPair.privateKey)
    
    // 字符串签名，返回 Base64
    let signatureBase64 = try XCECDSAKey.sign(string: "payload", privateKey: keyPair.privateKey)
    
    // raw (r||s) 64 字节格式（部分服务端或 JWT 使用）
    let rawSignature = try XCECDSAKey.signRaw(data: payloadData, privateKey: keyPair.privateKey)
} catch {
    print("签名失败：\(error.localizedDescription)")
}
```

### 5.4 验签

```swift
do {
    let keyPair = XCECDSAKey.generateKeyPair()
    let signature = try XCECDSAKey.sign(data: payloadData, privateKey: keyPair.privateKey)
    
    // DER 格式验签
    let isValid = try XCECDSAKey.verify(
        data: payloadData,
        signature: signature,
        publicKey: keyPair.publicKey
    )
    
    // Base64 签名验签
    let signatureBase64 = try XCECDSAKey.sign(string: "payload", privateKey: keyPair.privateKey)
    let isValid2 = try XCECDSAKey.verify(
        string: "payload",
        base64Signature: signatureBase64,
        publicKey: keyPair.publicKey
    )
    
    // raw 格式验签
    let rawSignature = try XCECDSAKey.signRaw(data: payloadData, privateKey: keyPair.privateKey)
    let isValid3 = try XCECDSAKey.verifyRaw(
        data: payloadData,
        rawSignature: rawSignature,
        publicKey: keyPair.publicKey
    )
    
    print("验签：\(isValid), \(isValid2), \(isValid3)")
} catch {
    print("验签失败：\(error.localizedDescription)")
}
```

### 5.5 签名格式说明

| 格式 | 方法 | 长度 | 适用场景 |
|---|---|---|---|
| DER 编码 | `sign` / `verify` | 约 70-72 字节 | 标准 X.509、TLS |
| raw (r\|\|s) | `signRaw` / `verifyRaw` | 固定 64 字节 | JWT (ES256)、部分 API |

### 5.6 错误类型

```swift
XCECDSAKey.ECDSAError.invalidKeyData
XCECDSAKey.ECDSAError.signingFailed("原因")
XCECDSAKey.ECDSAError.verificationFailed("原因")
```

---

## 6. XCRandom — 安全随机数生成

> 底层使用 `SecRandomCopyBytes`，具备密码学安全等级。

### 6.1 随机字节

```swift
// 生成 32 字节随机 Data
let randomBytes = XCRandom.bytes(count: 32)
print(XCCryptoEncoding.hexEncode(randomBytes))
```

### 6.2 随机字符串

```swift
// 内置字符集
let token1 = XCRandom.string(length: 32)                          // alphanumeric（默认）
let token2 = XCRandom.string(length: 16, charset: .hex)           // 十六进制
let token3 = XCRandom.string(length: 8,  charset: .numeric)       // 纯数字
let token4 = XCRandom.string(length: 20, charset: .lowercase)     // 小写字母
let token5 = XCRandom.string(length: 20, charset: .uppercase)     // 大写字母
let token6 = XCRandom.string(length: 16, charset: .alphabetic)    // 大小写字母

// 自定义字符集
let token7 = XCRandom.string(length: 12, from: "ABCDEF0123456789")
```

### 6.3 随机整数

```swift
// 半开区间 [0, 100)
let num1 = XCRandom.int(in: 0..<100)

// 闭区间 [1, 6]（模拟骰子）
let num2 = XCRandom.int(in: 1...6)
```

### 6.4 UUID

```swift
// 基于 SecRandomCopyBytes，符合 RFC 4122 v4
let uuid = XCRandom.uuid()
// "A1B2C3D4-E5F6-4789-8012-1A2B3C4D5E6F"
```

### 6.5 AES 密钥生成

```swift
// 生成 SymmetricKey（直接用于 XCAES / XCChaChaPoly）
let key128 = XCRandom.aesKey(bits: 128)
let key256 = XCRandom.aesKey(bits: 256) // 默认

// 生成并导出为 Data（用于存储到 Keychain）
let keyData = XCRandom.aesKeyData(bits: 256)
```

### 6.6 PIN / OTP

```swift
// 6 位数字 PIN
let pin = XCRandom.pin()          // "384729"
let pin4 = XCRandom.pin(length: 4) // "4821"

// 32 位 alphanumeric Token
let token = XCRandom.token()       // "kR3mP9xQv2..."
let token64 = XCRandom.token(length: 64)
```

---

## 7. XCCryptoEncoding — 编解码工具

### 7.1 Base64

```swift
// Data → Base64
let encoded = XCCryptoEncoding.base64Encode(someData)

// Base64 → Data（自动补 padding）
if let data = XCCryptoEncoding.base64Decode(encodedString) {
    print("解码成功，\(data.count) 字节")
}
```

### 7.2 Base64URL（URL-safe）

```swift
// Data → URL-safe Base64（`+`→`-`, `/`→`_`，无 `=` padding）
let urlEncoded = XCCryptoEncoding.base64URLEncode(someData)

// URL-safe Base64 → Data
if let data = XCCryptoEncoding.base64URLDecode(urlEncodedString) {
    print("解码成功")
}
```

> JWT、OAuth 2.0 的 PKCE code_challenge 等场景均使用 Base64URL。

### 7.3 Hex（十六进制）

```swift
// Data → 十六进制字符串（默认小写）
let hex = XCCryptoEncoding.hexEncode(someData)
// "deadbeef"

// 大写
let hexUpper = XCCryptoEncoding.hexEncode(someData, uppercase: true)
// "DEADBEEF"

// 十六进制字符串 → Data（支持空格、0x 前缀）
if let data = XCCryptoEncoding.hexDecode("de ad be ef") { ... }
if let data = XCCryptoEncoding.hexDecode("0xdeadbeef") { ... }
```

### 7.4 格式互转

```swift
// Base64 → Hex
let hex = XCCryptoEncoding.base64ToHex("SGVsbG8=")
// "48656c6c6f"

// Hex → Base64
let base64 = XCCryptoEncoding.hexToBase64("48656c6c6f")
// "SGVsbG8="

// Hex → Base64URL
let base64url = XCCryptoEncoding.hexToBase64URL("48656c6c6f")
// "SGVsbG8"
```

---

## 8. String 扩展 — 哈希与编解码快捷调用

> `XCCryptoEncoding.swift` 中通过 `String` 扩展提供了快捷属性，`import XCCrypto` 后即可使用。

### 8.1 哈希

```swift
let md5    = "hello".md5String     // "5d41402a..."
let sha1   = "hello".sha1String    // "aaf4c61d..."
let sha256 = "hello".sha256String  // "2cf24dba..."
let sha512 = "hello".sha512String  // "9b71d224..."

// HMAC
let hmac256 = "payload".hmacSHA256(key: "secret")
let hmac512 = "payload".hmacSHA512(key: "secret")
```

### 8.2 Base64 编解码

```swift
// Base64
let encoded = "Hello, World!".base64Encoded   // Optional("SGVsbG8sIFdvcmxkIQ==")
let decoded = "SGVsbG8sIFdvcmxkIQ==".base64Decoded // Optional("Hello, World!")

// URL-safe Base64
let urlEncoded = "Hello".base64URLEncoded      // Optional("SGVsbG8")
let urlDecoded = "SGVsbG8".base64URLDecoded    // Optional("Hello")
```

### 8.3 URL 编解码

```swift
let encoded = "name=张三&age=25".urlEncoded
// Optional("name%3D%E5%BC%A0%E4%B8%89%26age%3D25")

let decoded = "name%3D%E5%BC%A0%E4%B8%89".urlDecoded
// Optional("name=张三")
```

---

## 9. 算法选型指南

### 9.1 对称加密

| 场景 | 推荐算法 | 原因 |
|---|---|---|
| 新项目本地数据加密 | **AES-GCM** | 现代、AEAD、API 简洁 |
| 移动端 P2P 通信 | **ChaCha20-Poly1305** | 无硬件加速时性能更优 |
| 对接旧服务端 | **AES-CBC** | 兼容性最好 |
| 密钥长度 | **256-bit** | 安全性最高，性能差异可忽略 |

### 9.2 非对称加密 / 签名

| 场景 | 推荐算法 | 原因 |
|---|---|---|
| 数据加密传输（小数据） | **RSA-OAEP** | 广泛兼容 |
| 大数据加密 | **混合加密**（RSA + AES-GCM） | RSA 单次限制约 190 字节 |
| API 请求签名 | **ECDSA P-256** 或 **HMAC-SHA256** | P-256 密钥短，HMAC 性能更高 |
| JWT 签名 | **ECDSA P-256**（ES256） | 业界标准 |
| 设备身份认证 | **ECDSA P-256** | CryptoKit 原生支持 Secure Enclave |

### 9.3 哈希选型

| 场景 | 推荐 |
|---|---|
| 密码存储 | ❌ 以上均不适合，应使用 bcrypt / Argon2 |
| 文件完整性校验 | SHA-256 |
| API 接口签名 | HMAC-SHA256 |
| 缓存 key / 非安全场景 | MD5 或 SHA-1（速度快） |
| 证书、数字签名场景 | SHA-256 或 SHA-512 |

---

## 10. 错误处理

### 统一处理模式

```swift
do {
    let result = try XCAES.gcmEncrypt(data: data, key: keyData)
} catch let error as XCAES.AESError {
    switch error {
    case .invalidKeySize:
        print("密钥长度错误，应为 16/24/32 字节")
    case .invalidIVSize:
        print("IV 长度错误，应为 16 字节")
    case .encryptionFailed:
        print("加密失败")
    case .decryptionFailed:
        print("解密失败，可能是密钥错误或数据被篡改")
    case .invalidCombinedData:
        print("密文格式错误")
    }
} catch {
    print("未知错误：\(error.localizedDescription)")
}
```

### 链式操作（Result 包装）

```swift
func safeEncrypt(_ text: String, key: Data) -> Result<String, Error> {
    Result {
        guard let data = text.data(using: .utf8) else {
            throw XCAES.AESError.encryptionFailed
        }
        let combined = try XCAES.gcmEncrypt(data: data, key: key)
        return combined.base64EncodedString()
    }
}

// 使用
switch safeEncrypt("hello", key: keyData) {
case .success(let base64):
    print("加密结果：\(base64)")
case .failure(let error):
    print("加密失败：\(error.localizedDescription)")
}
```

### async/await 包装（网络场景）

```swift
func encryptAndUpload(data: Data, key: Data) async throws -> String {
    // 加密
    let combined = try XCAES.gcmEncrypt(data: data, key: key)
    let base64 = combined.base64EncodedString()
    
    // 上传（示例）
    let response = try await uploadToServer(base64: base64)
    return response
}
```

---

*文档版本：1.0 · 对应 XCCrypto v1.0 · iOS 13+*
