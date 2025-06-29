import Foundation

public class XcodeProjectFinder {
    public enum ProjectError: Error, LocalizedError {
        case noProjectFound
        case multipleProjectsFound([String])
        case invalidPath(String)
        
        public var errorDescription: String? {
            switch self {
            case .noProjectFound:
                return "No Xcode project (.xcodeproj) or workspace (.xcworkspace) found in the current directory or subdirectories"
            case .multipleProjectsFound(let projects):
                return "Multiple Xcode projects found. Please specify which one to use: \(projects.joined(separator: ", "))"
            case .invalidPath(let path):
                return "Invalid path: \(path)"
            }
        }
    }
    
    public static func findXcodeProject(in directory: String) throws -> String {
        let fileManager = FileManager.default
        let directoryURL = URL(fileURLWithPath: directory)
        
        // First, try to find .xcworkspace files
        let workspaceFiles = try findFiles(withExtension: "xcworkspace", in: directoryURL, fileManager: fileManager)
        
        if workspaceFiles.count == 1 {
            return workspaceFiles[0]
        } else if workspaceFiles.count > 1 {
            throw ProjectError.multipleProjectsFound(workspaceFiles)
        }
        
        // If no workspace found, try to find .xcodeproj files
        let projectFiles = try findFiles(withExtension: "xcodeproj", in: directoryURL, fileManager: fileManager)
        
        if projectFiles.count == 1 {
            return projectFiles[0]
        } else if projectFiles.count > 1 {
            // Only error if there are no .xcworkspace files found
            // (if there were multiple .xcworkspace files, we already errored above)
            throw ProjectError.multipleProjectsFound(projectFiles)
        }
        
        // No projects found
        throw ProjectError.noProjectFound
    }
    
    public static func resolveProjectPath(_ projectPath: String, relativeTo baseDirectory: String) -> String {
        let fileManager = FileManager.default
        
        // If it's already an absolute path, return it
        if projectPath.hasPrefix("/") {
            return projectPath
        }
        
        // Try relative path first
        let relativeURL = URL(fileURLWithPath: baseDirectory).appendingPathComponent(projectPath)
        if fileManager.fileExists(atPath: relativeURL.path) {
            return relativeURL.path
        }
        
        // If relative path doesn't exist, try as absolute path
        if fileManager.fileExists(atPath: projectPath) {
            return projectPath
        }
        
        // If neither works, return the relative path (will be handled by caller)
        return relativeURL.path
    }
    
    private static func findFiles(withExtension ext: String, in directory: URL, fileManager: FileManager) throws -> [String] {
        var files: [String] = []
        
        func searchDirectory(_ url: URL) throws {
            let contents = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
            
            for item in contents {
                let isDirectory = (try? item.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false
                let lastComponent = item.lastPathComponent
                // Skip dot directories
                if isDirectory && lastComponent.hasPrefix(".") {
                    continue
                }
                if isDirectory && item.pathExtension == ext {
                    files.append(item.path)
                } else if isDirectory {
                    // Recursively search subdirectories
                    try searchDirectory(item)
                }
            }
        }
        
        try searchDirectory(directory)
        return files
    }
} 