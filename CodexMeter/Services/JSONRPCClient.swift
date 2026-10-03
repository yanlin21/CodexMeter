import Foundation
import OSLog

final class JSONRPCClient: @unchecked Sendable {
    private let executableURL: URL
    private let process = Process()
    private let inputPipe = Pipe()
    private let outputPipe = Pipe()
    private let errorPipe = Pipe()
    private let condition = NSCondition()
    private let parserQueue = DispatchQueue(label: "com.codexmeter.jsonrpc.parser")
    private let logger = Logger(subsystem: "com.codexmeter.app", category: "JSONRPC")

    private var nextID = 1
    private var responses: [Int: [String: Any]] = [:]
    private var outputBuffer = Data()
    private var processExited = false
    private var started = false

    init(executableURL: URL) {
        self.executableURL = executableURL
    }

    func start() throws {
        guard !started else { return }
        process.executableURL = executableURL
        process.arguments = ["app-server", "--stdio"]
        process.standardInput = inputPipe
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        outputPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty else {
                self?.markExited()
                return
            }
            self?.parserQueue.async { self?.consume(data) }
        }
        errorPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty, let text = String(data: data, encoding: .utf8) else { return }
            self?.logger.debug("Codex app-server: \(text, privacy: .private)")
        }
        process.terminationHandler = { [weak self] _ in self?.markExited() }

        do {
            try process.run()
            started = true
        } catch {
            clearHandlers()
            throw ClientError.couldNotStart(error.localizedDescription)
        }
    }

    func request(method: String, params: Any? = nil, timeout: TimeInterval = 15) throws -> [String: Any] {
        let id: Int = condition.withLock {
            defer { nextID += 1 }
            return nextID
        }
        var message: [String: Any] = ["id": id, "method": method]
        if let params { message["params"] = params }
        try write(message)

        let deadline = Date().addingTimeInterval(timeout)
        condition.lock()
        defer { condition.unlock() }
        while responses[id] == nil && !processExited {
            if !condition.wait(until: deadline) { break }
        }
        guard let response = responses.removeValue(forKey: id) else {
            if processExited { throw ClientError.processExited }
            throw ClientError.timedOut(method)
        }
        if let error = response["error"] as? [String: Any] {
            let message = error["message"] as? String ?? "Unknown JSON-RPC error"
            let code = error["code"] as? Int ?? -1
            throw ClientError.rpc(code: code, message: message)
        }
        guard let result = response["result"] as? [String: Any] else {
            if response["result"] is NSNull { return [:] }
            throw ClientError.invalidResponse(method)
        }
        return result
    }

    func sendNotification(method: String, params: Any? = nil) throws {
        var message: [String: Any] = ["method": method]
        if let params { message["params"] = params }
        try write(message)
    }

    func stop() {
        clearHandlers()
        try? inputPipe.fileHandleForWriting.close()
        if process.isRunning { process.terminate() }
        markExited()
    }

    deinit {
        stop()
    }

    private func write(_ value: [String: Any]) throws {
        guard started, process.isRunning else { throw ClientError.processExited }
        guard JSONSerialization.isValidJSONObject(value) else { throw ClientError.couldNotEncode }
        var data = try JSONSerialization.data(withJSONObject: value)
        data.append(0x0A)
        do {
            try inputPipe.fileHandleForWriting.write(contentsOf: data)
        } catch {
            throw ClientError.writeFailed(error.localizedDescription)
        }
    }

    private func consume(_ data: Data) {
        outputBuffer.append(data)
        while let newline = outputBuffer.firstIndex(of: 0x0A) {
            let line = outputBuffer[..<newline]
            outputBuffer.removeSubrange(...newline)
            guard !line.isEmpty,
                  let object = try? JSONSerialization.jsonObject(with: Data(line)),
                  let message = object as? [String: Any],
                  let id = Self.integerID(message["id"])
            else {
                // Notifications and non-protocol stdout are intentionally ignored.
                continue
            }
            condition.lock()
            responses[id] = message
            condition.broadcast()
            condition.unlock()
        }
    }

    private func markExited() {
        condition.lock()
        processExited = true
        condition.broadcast()
        condition.unlock()
    }

    private func clearHandlers() {
        outputPipe.fileHandleForReading.readabilityHandler = nil
        errorPipe.fileHandleForReading.readabilityHandler = nil
        process.terminationHandler = nil
    }

    private static func integerID(_ value: Any?) -> Int? {
        if let int = value as? Int { return int }
        if let number = value as? NSNumber { return number.intValue }
        if let string = value as? String { return Int(string) }
        return nil
    }

    enum ClientError: LocalizedError {
        case couldNotStart(String)
        case processExited
        case timedOut(String)
        case rpc(code: Int, message: String)
        case invalidResponse(String)
        case couldNotEncode
        case writeFailed(String)

        var errorDescription: String? {
            switch self {
            case .couldNotStart(let detail): "Could not start Codex App Server: \(detail)"
            case .processExited: "Codex App Server exited unexpectedly."
            case .timedOut(let method): "Timed out while waiting for \(method)."
            case .rpc(_, let message): message
            case .invalidResponse(let method): "Invalid response from \(method)."
            case .couldNotEncode: "Could not encode a JSON-RPC request."
            case .writeFailed(let detail): "Could not write to Codex App Server: \(detail)"
            }
        }
    }
}

private extension NSCondition {
    func withLock<T>(_ body: () -> T) -> T {
        lock()
        defer { unlock() }
        return body()
    }
}

