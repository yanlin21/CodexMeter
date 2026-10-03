import Foundation

struct CodexExecutableLocator: Sendable {
    func locate() -> URL? {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let candidates = [
            "/opt/homebrew/bin/codex",
            "/usr/local/bin/codex",
            "/usr/bin/codex",
            "\(home)/.local/bin/codex",
            "\(home)/.npm-global/bin/codex",
            "/Applications/ChatGPT.app/Contents/Resources/codex-cli/CodexCLI.app/Contents/MacOS/codex"
        ]

        for path in candidates where FileManager.default.isExecutableFile(atPath: path) {
            return URL(fileURLWithPath: path).resolvingSymlinksInPath()
        }

        return locateWithLoginShell()
    }

    private func locateWithLoginShell() -> URL? {
        let process = Process()
        let output = Pipe()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-lc", "command -v codex"]
        process.standardOutput = output
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            process.waitUntilExit()
            guard process.terminationStatus == 0 else { return nil }
            let data = output.fileHandleForReading.readDataToEndOfFile()
            guard let text = String(data: data, encoding: .utf8) else { return nil }
            for line in text.split(whereSeparator: \Character.isNewline) {
                let path = String(line).trimmingCharacters(in: .whitespacesAndNewlines)
                if path.hasPrefix("/"), FileManager.default.isExecutableFile(atPath: path) {
                    return URL(fileURLWithPath: path).resolvingSymlinksInPath()
                }
            }
        } catch {
            return nil
        }
        return nil
    }
}

