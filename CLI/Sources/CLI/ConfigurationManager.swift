import Foundation
import PListKit

public class ConfigurationManager {
    public enum Error: Swift.Error, LocalizedError {
        case fileNotFound(String)
        case writeError(String)
        case readError(String)
        case directoryCreationError(String)
        case plistParseError(String)
        
        public var errorDescription: String? {
            switch self {
            case .fileNotFound(let path):
                return "Configuration file not found: \(path)"
            case .writeError(let message):
                return "Failed to write configuration file: \(message)"
            case .readError(let message):
                return "Failed to read configuration file: \(message)"
            case .directoryCreationError(let message):
                return "Failed to create configuration directory: \(message)"
            case .plistParseError(let message):
                return "Failed to parse plist configuration: \(message)"
            }
        }
    }
    
    /// The default configuration directory name
    public static let configDirectoryName = ".xcodecli"
    
    /// The configuration file name within the directory
    public static let configFileName = "config.plist"
    
    /// Get the full path to the configuration file
    public static func getConfigFilePath(in directory: String) -> String {
        return URL(fileURLWithPath: directory)
            .appendingPathComponent(configDirectoryName)
            .appendingPathComponent(configFileName)
            .path
    }
    
    /// Get the configuration directory path
    public static func getConfigDirectoryPath(in directory: String) -> String {
        return URL(fileURLWithPath: directory)
            .appendingPathComponent(configDirectoryName)
            .path
    }
    
    public static func readConfiguration(from path: String) throws -> ProgramConfiguration {
        let configPath = getConfigFilePath(in: path)
        
        guard FileManager.default.fileExists(atPath: configPath) else {
            return ProgramConfiguration() // Return empty configuration if file doesn't exist
        }
        
        do {
            return try ConfigurationParser.parseConfigurationFile(at: configPath)
        } catch {
            throw Error.readError(error.localizedDescription)
        }
    }
    
    public static func writeConfiguration(_ config: ProgramConfiguration, to path: String) throws {
        let configDir = getConfigDirectoryPath(in: path)
        let configPath = getConfigFilePath(in: path)
        
        // Create the configuration directory if it doesn't exist
        if !FileManager.default.fileExists(atPath: configDir) {
            do {
                try FileManager.default.createDirectory(atPath: configDir, withIntermediateDirectories: true)
            } catch {
                throw Error.directoryCreationError(error.localizedDescription)
            }
        }
        
        let plistContent = generateConfigurationPlist(config)
        
        do {
            try plistContent.write(toFile: configPath, atomically: true, encoding: .utf8)
        } catch {
            throw Error.writeError(error.localizedDescription)
        }
    }
    
    private static func generateConfigurationPlist(_ config: ProgramConfiguration) -> String {
        let plist = config.toPlist()
        return try! String(data: plist.rawData(), encoding: .utf8) ?? ""
    }
} 
