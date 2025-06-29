import Foundation
import PListKit

public class PackageLocation {
    public enum Error: Swift.Error, LocalizedError {
        case fileNotFound(String)
        case writeError(String)
        case readError(String)
        case directoryCreationError(String)
        case plistParseError(String)
        
        public var errorDescription: String? {
            switch self {
            case .fileNotFound(let path):
                return "Packages file not found: \(path)"
            case .writeError(let message):
                return "Failed to write packages file: \(message)"
            case .readError(let message):
                return "Failed to read packages file: \(message)"
            case .directoryCreationError(let message):
                return "Failed to create packages directory: \(message)"
            case .plistParseError(let message):
                return "Failed to parse plist packages file: \(message)"
            }
        }
    }
    
    /// The default packages directory name
    public static let packagesDirectoryName = ".xcodecli"
    
    /// The packages file name within the directory
    public static let packagesFileName = "packages.plist"
    
    /// Get the full path to the packages file
    public static func getPackagesFilePath(in directory: String) -> String {
        return URL(fileURLWithPath: directory)
            .appendingPathComponent(packagesDirectoryName)
            .appendingPathComponent(packagesFileName)
            .path
    }
    
    /// Get the packages directory path
    public static func getPackagesDirectoryPath(in directory: String) -> String {
        return URL(fileURLWithPath: directory)
            .appendingPathComponent(packagesDirectoryName)
            .path
    }
    
    public static func read(from path: String) throws -> [String] {
        let packagesPath = getPackagesFilePath(in: path)
        
        guard FileManager.default.fileExists(atPath: packagesPath) else {
            return [] // Return empty array if file doesn't exist
        }
        
        do {
            let content = try String(contentsOfFile: packagesPath, encoding: .utf8)
            let plist = try ArrayPList(xml: content)
            return plist.storage.compactMap { $0 as? String }
        } catch {
            throw Error.readError(error.localizedDescription)
        }
    }
    
    public static func write(_ packages: [String], to path: String) throws {
        let packagesDir = getPackagesDirectoryPath(in: path)
        let packagesPath = getPackagesFilePath(in: path)
        
        // Create the packages directory if it doesn't exist
        if !FileManager.default.fileExists(atPath: packagesDir) {
            do {
                try FileManager.default.createDirectory(atPath: packagesDir, withIntermediateDirectories: true)
            } catch {
                throw Error.directoryCreationError(error.localizedDescription)
            }
        }
        
        let plist = ArrayPList()
        for packagePath in packages {
            plist.storage.append(packagePath)
        }
        let data = try PropertyListSerialization.data(fromPropertyList: plist.storage, format: .xml, options: 0)
        guard let plistContent = String(data: data, encoding: .utf8) else {
            throw Error.writeError("Failed to encode plist data as UTF-8 string.")
        }
        
        do {
            try plistContent.write(toFile: packagesPath, atomically: true, encoding: String.Encoding.utf8)
        } catch {
            throw Error.writeError(error.localizedDescription)
        }
    }
    
    public static func update(at path: String, with newPackagePath: String) throws {
        var packages: [String]
        
        // Try to read existing packages, or create new empty array if file doesn't exist
        if FileManager.default.fileExists(atPath: getPackagesFilePath(in: path)) {
            packages = try read(from: path)
        } else {
            packages = []
        }
        
        // Remove existing package with same path if it exists
        let updatedPackages = packages.filter { $0 != newPackagePath }
        
        // Add the new package
        let finalPackages = updatedPackages + [newPackagePath]
        
        // Write back to file
        try write(finalPackages, to: path)
    }
} 
