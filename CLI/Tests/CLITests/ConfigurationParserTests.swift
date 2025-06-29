import Foundation
import Testing
@testable import CLI

@Suite("Configuration Parser Tests")
struct ConfigurationParserTests {
    
    // MARK: - Plist Format Tests
    
    @Test("Parse configuration with project (plist format)")
    func parseConfigurationWithProjectPlist() throws {
        let content = """
        <?xml version=\"1.0\" encoding=\"UTF-8\"?>
        <!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">
        <plist version=\"1.0\">
        <dict>
            <key>Project</key>
            <string>~/Projects/MyApp.xcodeproj</string>
        </dict>
        </plist>
        """
        
        let commandConfig = try ConfigurationParser.parseConfiguration(content: content)
        
        #expect(commandConfig.project == "~/Projects/MyApp.xcodeproj")
        #expect(commandConfig.workspace == nil)
    }
    
    @Test("Parse configuration with workspace (plist format)")
    func parseConfigurationWithWorkspacePlist() throws {
        let content = """
        <?xml version=\"1.0\" encoding=\"UTF-8\"?>
        <!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">
        <plist version=\"1.0\">
        <dict>
            <key>Workspace</key>
            <string>~/Projects/MyApp.xcworkspace</string>
        </dict>
        </plist>
        """
        
        let commandConfig = try ConfigurationParser.parseConfiguration(content: content)
        
        #expect(commandConfig.project == nil)
        #expect(commandConfig.workspace == "~/Projects/MyApp.xcworkspace")
    }
    
    @Test("Parse configuration with both project and workspace (plist format)")
    func parseConfigurationWithBothProjectAndWorkspacePlist() throws {
        let content = """
        <?xml version=\"1.0\" encoding=\"UTF-8\"?>
        <!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">
        <plist version=\"1.0\">
        <dict>
            <key>Project</key>
            <string>~/Projects/MyApp.xcodeproj</string>
            <key>Workspace</key>
            <string>~/Projects/MyApp.xcworkspace</string>
        </dict>
        </plist>
        """
        
        let commandConfig = try ConfigurationParser.parseConfiguration(content: content)
        
        #expect(commandConfig.project == "~/Projects/MyApp.xcodeproj")
        #expect(commandConfig.workspace == "~/Projects/MyApp.xcworkspace")
    }
    
    @Test("Parse configuration with complex paths (plist format)")
    func parseConfigurationWithComplexPathsPlist() throws {
        let content = """
        <?xml version=\"1.0\" encoding=\"UTF-8\"?>
        <!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">
        <plist version=\"1.0\">
        <dict>
            <key>Project</key>
            <string>~/Projects/My Project/App Name.xcodeproj</string>
            <key>Workspace</key>
            <string>/Users/username/Projects/My Project/App Name.xcworkspace</string>
        </dict>
        </plist>
        """
        
        let commandConfig = try ConfigurationParser.parseConfiguration(content: content)
        
        #expect(commandConfig.project == "~/Projects/My Project/App Name.xcodeproj")
        #expect(commandConfig.workspace == "/Users/username/Projects/My Project/App Name.xcworkspace")
    }
    
    @Test("Parse configuration with empty content (plist format)")
    func parseConfigurationWithEmptyContentPlist() throws {
        let content = """
        <?xml version=\"1.0\" encoding=\"UTF-8\"?>
        <!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">
        <plist version=\"1.0\">
        <dict>
        </dict>
        </plist>
        """
        
        let commandConfig = try ConfigurationParser.parseConfiguration(content: content)
        
        #expect(commandConfig.project == nil)
        #expect(commandConfig.workspace == nil)
    }
    
    @Test("Parse configuration file (plist format)")
    func parseConfigurationFilePlist() throws {
        // Create a temporary file for testing
        let tempDir = FileManager.default.temporaryDirectory
        let tempFile = tempDir.appendingPathComponent("test_config.plist")
        
        let content = """
        <?xml version=\"1.0\" encoding=\"UTF-8\"?>
        <!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">
        <plist version=\"1.0\">
        <dict>
            <key>Project</key>
            <string>~/Projects/MyApp.xcodeproj</string>
            <key>Workspace</key>
            <string>~/Projects/MyApp.xcworkspace</string>
        </dict>
        </plist>
        """
        
        try content.write(to: tempFile, atomically: true, encoding: .utf8)
        defer {
            try? FileManager.default.removeItem(at: tempFile)
        }
        
        let commandConfig = try ConfigurationParser.parseConfigurationFile(at: tempFile.path)
        
        #expect(commandConfig.project == "~/Projects/MyApp.xcodeproj")
        #expect(commandConfig.workspace == "~/Projects/MyApp.xcworkspace")
    }
    
    @Test("Parse configuration file not found")
    func parseConfigurationFileNotFound() {
        let nonExistentPath = "/non/existent/path/config.plist"
        
        #expect(throws: (any Error).self) {
            try ConfigurationParser.parseConfigurationFile(at: nonExistentPath)
        }
    }
} 