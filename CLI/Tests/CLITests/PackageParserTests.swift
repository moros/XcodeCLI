import Foundation
import Testing
@testable import CLI

@Suite("Package Parser Tests")
struct PackageParserTests {
    
    // MARK: - Plist Array Format Tests
    
    @Test("Parse package (plist array format)")
    func parsePackagePlist() throws {
        let content = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <array>
            <string>/path/to/package</string>
        </array>
        </plist>
        """
        let packages = try PackageParser.parsePackagesContent(content)
        
        #expect(packages.count == 1)
        #expect(packages[0] == "/path/to/package")
    }
    
    @Test("Parse multiple packages (plist array format)")
    func parseMultiplePackagesPlist() throws {
        let content = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <array>
            <string>/path/to/package1</string>
            <string>/path/to/package2</string>
        </array>
        </plist>
        """
        let packages = try PackageParser.parsePackagesContent(content)
        
        #expect(packages.count == 2)
        #expect(packages[0] == "/path/to/package1")
        #expect(packages[1] == "/path/to/package2")
    }
    
    @Test("Parse package with complex path (plist array format)")
    func parsePackageWithComplexPathPlist() throws {
        let content = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <array>
            <string>/Users/username/Projects/My Project/Package Name</string>
        </array>
        </plist>
        """
        let packages = try PackageParser.parsePackagesContent(content)
        
        #expect(packages.count == 1)
        #expect(packages[0] == "/Users/username/Projects/My Project/Package Name")
    }
    
    @Test("Parse package with special characters (plist array format)")
    func parsePackageWithSpecialCharactersPlist() throws {
        let content = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <array>
            <string>/path/with/special-chars_123</string>
        </array>
        </plist>
        """
        let packages = try PackageParser.parsePackagesContent(content)
        
        #expect(packages.count == 1)
        #expect(packages[0] == "/path/with/special-chars_123")
    }
    
    @Test("Parse empty packages (plist array format)")
    func parseEmptyPackagesPlist() throws {
        let content = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <array>
        </array>
        </plist>
        """
        let packages = try PackageParser.parsePackagesContent(content)
        
        #expect(packages.isEmpty)
    }
} 