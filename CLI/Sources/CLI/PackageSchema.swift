import Foundation

public struct PackageSchema: Codable {
    public let name: String
    public let products: [Library]

    public struct Library: Codable {
        public let name: String
        public let targets: [String]
    }

    public static func parseSchema(fromPath path: String) throws -> PackageSchema {
        let process = Process()
        process.currentDirectoryPath = path
        process.launchPath = "/usr/bin/env"
        process.arguments = ["swift", "package", "dump-package"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()
        try process.run()
        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let decoder = JSONDecoder()
        let manifest = try decoder.decode(PackageSchema.self, from: data)
        return manifest
    }
} 