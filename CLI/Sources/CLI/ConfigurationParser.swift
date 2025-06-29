import Foundation
import PListKit

public class ConfigurationParser {
    public enum ParseError: Error, LocalizedError {
        case invalidFormat(String)
        case missingRequiredField(String)
        case invalidPath(String)
        case plistParseError(String)
        
        public var errorDescription: String? {
            switch self {
            case .invalidFormat(let line):
                return "Invalid format in line: \(line)"
            case .missingRequiredField(let field):
                return "Missing required field: \(field)"
            case .invalidPath(let path):
                return "Invalid path: \(path)"
            case .plistParseError(let message):
                return "Plist parse error: \(message)"
            }
        }
    }
    
    public static func parseConfigurationFile(at path: String) throws -> ProgramConfiguration {
        let content = try String(contentsOfFile: path, encoding: .utf8)
        return try parseConfiguration(content: content)
    }
    
    public static func parseConfiguration(content: String) throws -> ProgramConfiguration {
        do {
            let plist = try DictionaryPList(xml: content)
            return try ProgramConfiguration.fromPlist(plist)
        } catch {
            throw ParseError.plistParseError(error.localizedDescription)
        }
    }
} 
