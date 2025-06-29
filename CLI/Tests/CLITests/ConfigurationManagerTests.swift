import Foundation
import Testing
@testable import CLI

@Suite("Configuration Manager Tests")
struct ConfigurationManagerTests {
    
    @Test("Write and read configuration")
    func writeAndReadConfiguration() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let configDir = tempDir
        let configPath = configDir.path
        
        let config = ProgramConfiguration(
            project: "/path/to/project.xcodeproj",
            workspace: "/path/to/workspace.xcworkspace"
        )
        
        // Write configuration
        try ConfigurationManager.writeConfiguration(config, to: configPath)
        
        // Verify the directory and file were created
        let expectedConfigDir = URL(fileURLWithPath: configPath)
            .appendingPathComponent(".xcodecli")
        let expectedConfigFile = expectedConfigDir.appendingPathComponent("config.plist")
        
        #expect(FileManager.default.fileExists(atPath: expectedConfigDir.path))
        #expect(FileManager.default.fileExists(atPath: expectedConfigFile.path))
        
        // Read configuration back
        let readConfig = try ConfigurationManager.readConfiguration(from: configPath)
        
        // Verify the configuration was written and read correctly
        #expect(readConfig.project == "/path/to/project.xcodeproj")
        #expect(readConfig.workspace == "/path/to/workspace.xcworkspace")
        
        // Clean up
        try? FileManager.default.removeItem(at: expectedConfigDir)
    }
    
    @Test("Write and read configuration with only project")
    func writeAndReadConfigurationWithOnlyProject() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let configDir = tempDir
        let configPath = configDir.path
        
        let config = ProgramConfiguration(
            project: "/path/to/project.xcodeproj",
            workspace: nil
        )
        
        // Write configuration
        try ConfigurationManager.writeConfiguration(config, to: configPath)
        
        // Read configuration back
        let readConfig = try ConfigurationManager.readConfiguration(from: configPath)
        
        // Verify the configuration was written and read correctly
        #expect(readConfig.project == "/path/to/project.xcodeproj")
        #expect(readConfig.workspace == nil)
        
        // Clean up
        let expectedConfigDir = URL(fileURLWithPath: configPath)
            .appendingPathComponent(".xcodecli")
        try? FileManager.default.removeItem(at: expectedConfigDir)
    }
    
    @Test("Read configuration when file doesn't exist")
    func readConfigurationWhenFileDoesntExist() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let configPath = tempDir.appendingPathComponent("non_existent_dir").path
        
        // Read configuration from non-existent path
        let readConfig = try ConfigurationManager.readConfiguration(from: configPath)
        
        // Should return empty configuration
        #expect(readConfig.project == nil)
        #expect(readConfig.workspace == nil)
    }
    
    @Test("Plist format validation")
    func plistFormatValidation() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let configPath = tempDir.path
        
        let config = ProgramConfiguration(
            project: "/path/to/project.xcodeproj",
            workspace: "/path/to/workspace.xcworkspace"
        )
        
        // Write configuration
        try ConfigurationManager.writeConfiguration(config, to: configPath)
        
        // Read the raw plist content
        let expectedConfigFile = URL(fileURLWithPath: configPath)
            .appendingPathComponent(".xcodecli")
            .appendingPathComponent("config.plist")
        let plistContent = try String(contentsOf: expectedConfigFile, encoding: .utf8)
        
        // Verify plist structure
        #expect(plistContent.contains("<key>Project</key>"))
        #expect(plistContent.contains("<string>/path/to/project.xcodeproj</string>"))
        #expect(plistContent.contains("<key>Workspace</key>"))
        #expect(plistContent.contains("<string>/path/to/workspace.xcworkspace</string>"))
        
        // Clean up
        let expectedConfigDir = URL(fileURLWithPath: configPath)
            .appendingPathComponent(".xcodecli")
        try? FileManager.default.removeItem(at: expectedConfigDir)
    }
} 
