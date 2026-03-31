import Foundation

public enum Logger {
    public static var isEnabled: Bool = true

    public static func log(
        _ message: @autoclosure () -> String,
        file: String = #fileID,
        function: String = #function,
        line: Int = #line
    ) {
        guard isEnabled else { return }
        let fileName = (file as NSString).lastPathComponent
        print("[XCToolkit][\(fileName):\(line)] \(function) -> \(message())")
    }
}
