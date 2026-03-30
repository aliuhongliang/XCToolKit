import Foundation

public class Logger {
    public static var isEnabled: Bool = true
    public static func log(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        guard isEnabled else { return }
        let fileName = (file as NSString).lastPathComponent
        print("[XCToolkit][\(fileName):\(line)] \(function) -> \(message)")
    }
}
