import Foundation
import PListKit

public class PackageParser {
    public enum Error: Swift.Error, LocalizedError {
        case fileNotFound(String)
        case parseError(String)
        case plistParseError(String)
        
        public var errorDescription: String? {
            switch self {
            case .fileNotFound(let path):
                return "Packages file not found: \(path)"
            case .parseError(let message):
                return "Failed to parse packages file: \(message)"
            case .plistParseError(let message):
                return "Failed to parse plist packages file: \(message)"
            }
        }
    }
    
    public static func parsePackagesFile(at path: String) throws -> [String] {
        let content: String
        do {
            content = try String(contentsOfFile: path, encoding: .utf8)
        } catch {
            throw Error.fileNotFound(path)
        }
        return try parsePackagesContent(content)
    }
    
    public static func parsePackagesContent(_ content: String) throws -> [String] {
        do {
            let plist = try ArrayPList(xml: content)
            return plist.storage.compactMap { $0 as? String }
        } catch {
            throw Error.plistParseError(error.localizedDescription)
        }
    }
} 
