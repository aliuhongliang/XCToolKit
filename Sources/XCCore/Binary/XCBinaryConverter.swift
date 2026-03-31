import Foundation

public enum BinaryConverter {
    public static func hexString(from data: Data, uppercase: Bool = false) -> String {
        let format = uppercase ? "%02X" : "%02x"
        return data.map { String(format: format, $0) }.joined()
    }

    public static func data(fromHex hex: String) -> Data? {
        let cleanHex = hex.replacingOccurrences(of: " ", with: "")
        guard cleanHex.count.isMultiple(of: 2) else { return nil }

        var data = Data(capacity: cleanHex.count / 2)
        var index = cleanHex.startIndex
        while index < cleanHex.endIndex {
            let next = cleanHex.index(index, offsetBy: 2)
            let byteString = cleanHex[index..<next]
            guard let byte = UInt8(byteString, radix: 16) else { return nil }
            data.append(byte)
            index = next
        }
        return data
    }

    public static func bytes(from data: Data) -> [UInt8] {
        Array(data)
    }

    public static func data(from bytes: [UInt8]) -> Data {
        Data(bytes)
    }
}
