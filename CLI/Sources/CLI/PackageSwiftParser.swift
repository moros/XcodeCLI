import Foundation

public class PackageSwiftParser {
    public enum ParseError: Error, LocalizedError {
        case fileNotFound(String)
        case invalidFormat(String)
        case missingName
        case missingProducts
        case noLibrariesFound
        
        public var errorDescription: String? {
            switch self {
            case .fileNotFound(let path):
                return "Package.swift file not found at: \(path)"
            case .invalidFormat(let message):
                return "Invalid Package.swift format: \(message)"
            case .missingName:
                return "Package name not found in Package.swift"
            case .missingProducts:
                return "Products section not found in Package.swift"
            case .noLibrariesFound:
                return "No library products found in Package.swift"
            }
        }
    }
    
    public struct PackageInfo {
        public let name: String
        public let libraries: [String]
        
        public init(name: String, libraries: [String]) {
            self.name = name
            self.libraries = libraries
        }
    }
    
    public static func parsePackageSwift(at path: String) throws -> PackageInfo {
        let packageSwiftPath = URL(fileURLWithPath: path).appendingPathComponent("Package.swift")
        
        guard FileManager.default.fileExists(atPath: packageSwiftPath.path) else {
            throw ParseError.fileNotFound(packageSwiftPath.path)
        }
        
        let content = try String(contentsOf: packageSwiftPath, encoding: .utf8)
        return try parsePackageSwiftContent(content)
    }
    
    public static func parsePackageSwiftContent(_ content: String) throws -> PackageInfo {
        let lines = content.components(separatedBy: .newlines)
        
        // Extract package name
        let name = try extractPackageName(from: lines)
        
        // Extract library products
        let libraries = try extractLibraryProducts(from: lines)
        
        guard !libraries.isEmpty else {
            throw ParseError.noLibrariesFound
        }
        
        return PackageInfo(name: name, libraries: libraries)
    }
    
    private static func extractPackageName(from lines: [String]) throws -> String {
        var inPackageDeclaration = false
        var packageBuffer = ""
        var parenCount = 0
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if !inPackageDeclaration && trimmed.contains("Package(") {
                inPackageDeclaration = true
                if let idx = trimmed.firstIndex(of: "(") {
                    packageBuffer = String(trimmed[idx...])
                } else {
                    packageBuffer = trimmed
                }
                parenCount = packageBuffer.filter { $0 == "(" }.count - packageBuffer.filter { $0 == ")" }.count
                if parenCount == 0 {
                    inPackageDeclaration = false
                }
                continue
            }
            if inPackageDeclaration {
                packageBuffer += " " + trimmed
                parenCount += trimmed.filter { $0 == "(" }.count
                parenCount -= trimmed.filter { $0 == ")" }.count
                if parenCount == 0 {
                    inPackageDeclaration = false
                }
            }
        }
        // Only consider up to the first products:, targets:, dependencies:, or platforms:
        let stopKeywords = ["products:", "targets:", "dependencies:", "platforms:"]
        let stopIndex = stopKeywords.compactMap { keyword in
            packageBuffer.range(of: keyword)?.lowerBound
        }.sorted().first
        let searchBuffer = stopIndex != nil ? String(packageBuffer[..<stopIndex!]) : packageBuffer

        let namePattern = "name:\\s*['\\\"]([^'\\\"]+)['\\\"]"
        if let name = matchFirstGroup(in: searchBuffer, pattern: namePattern) {
            return name
        }
        throw ParseError.missingName
    }
    
    private static func extractLibraryProducts(from lines: [String]) throws -> [String] {
        var inProductsSection = false
        var libraries: [String] = []
        var braceCount = 0
        var bracketCount = 0
        var inLibraryDeclaration = false
        var currentLibraryBuffer = ""
        var parenCount = 0
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            // Check if we're entering the products section
            if !inProductsSection && (trimmedLine.contains("products:") || trimmedLine.contains("products =")) {
                inProductsSection = true
                braceCount += trimmedLine.filter { $0 == "{" }.count
                bracketCount += trimmedLine.filter { $0 == "[" }.count
                continue
            }
            if inProductsSection {
                braceCount += trimmedLine.filter { $0 == "{" }.count
                braceCount -= trimmedLine.filter { $0 == "}" }.count
                bracketCount += trimmedLine.filter { $0 == "[" }.count
                bracketCount -= trimmedLine.filter { $0 == "]" }.count
                // Check if we've exited the products section
                if braceCount <= 0 && bracketCount <= 0 && (trimmedLine.contains("}") || trimmedLine.contains("]")) {
                    break
                }
                // Buffer .library( declarations robustly
                if !inLibraryDeclaration && trimmedLine.contains(".library(") {
                    inLibraryDeclaration = true
                    currentLibraryBuffer = trimmedLine
                    parenCount = trimmedLine.filter { $0 == "(" }.count - trimmedLine.filter { $0 == ")" }.count
                    if parenCount == 0 {
                        // Single-line .library(
                        let name = extractLibraryName(from: currentLibraryBuffer)
                        if let name = name, !libraries.contains(name) {
                            libraries.append(name)
                        }
                        inLibraryDeclaration = false
                        currentLibraryBuffer = ""
                    }
                    continue
                }
                if inLibraryDeclaration {
                    currentLibraryBuffer += " " + trimmedLine
                    parenCount += trimmedLine.filter { $0 == "(" }.count
                    parenCount -= trimmedLine.filter { $0 == ")" }.count
                    if parenCount == 0 {
                        let name = extractLibraryName(from: currentLibraryBuffer)
                        if let name = name, !libraries.contains(name) {
                            libraries.append(name)
                        }
                        inLibraryDeclaration = false
                        currentLibraryBuffer = ""
                    }
                }
            }
        }
        return libraries
    }
    
    private static func extractLibraryName(from buffer: String) -> String? {
        // Match name: argument anywhere in the buffer
        let patterns = [
            "name:\\s*\"([^\"]+)\"",
            "name:\\s*'([^']+)'"
        ]
        for pattern in patterns {
            if let name = matchFirstGroup(in: buffer, pattern: pattern) {
                return name
            }
        }
        return nil
    }
    
    private static func matchFirstGroup(in text: String, pattern: String, group: Int = 1) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        guard let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) else { return nil }
        let range = match.range(at: group)
        guard let swiftRange = Range(range, in: text) else { return nil }
        return String(text[swiftRange])
    }
} 