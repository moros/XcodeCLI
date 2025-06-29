import Foundation
import Testing
@testable import CLI
import PListKit

@Suite("Package Location Tests")
struct PackageLocationTests {
    
    @Test("Write and read packages")
    func writeAndReadPackages() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let configDir = tempDir.appendingPathComponent("test_packages_dir")
        let configPath = configDir.path
        
        let packages = [
            "/path/to/package1",
            "/path/to/package2"
        ]
        
        // Write packages
        try PackageLocation.write(packages, to: configPath)
        
        // Verify the directory and file were created
        let expectedPackagesDir = URL(fileURLWithPath: configPath)
            .appendingPathComponent(".xcodecli")
        let expectedPackagesFile = expectedPackagesDir.appendingPathComponent("packages.plist")
        
        #expect(FileManager.default.fileExists(atPath: expectedPackagesDir.path))
        #expect(FileManager.default.fileExists(atPath: expectedPackagesFile.path))
        
        // Read packages back
        let readPackages = try PackageLocation.read(from: configPath)
        
        // Verify the packages were written and read correctly
        #expect(readPackages.count == 2)
        
        #expect(readPackages[0] == "/path/to/package1")
        #expect(readPackages[1] == "/path/to/package2")
        
        // Clean up
        try FileManager.default.removeItem(atPath: configDir.path)
    }
    
    @Test("Update packages")
    func updatePackages() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let configPath = tempDir.appendingPathComponent(".xcodecli")
        
        // Create initial packages
        let initialPackages = [
            "/path/to/package1"
        ]
        
        try PackageLocation.write(initialPackages, to: configPath.path)
        
        // Update with new package
        let newPackage = "/path/to/package2"
        try PackageLocation.update(at: configPath.path, with: newPackage)
        
        // Read back and verify
        let updatedPackages = try PackageLocation.read(from: configPath.path)
        #expect(updatedPackages.count == 2)
        #expect(updatedPackages.first { $0 == "/path/to/package1" } != nil)
        #expect(updatedPackages.first { $0 == "/path/to/package2" } != nil)
        
        // Update existing package (should replace)
        let updatedPackage = "/path/to/package1"
        try PackageLocation.update(at: configPath.path, with: updatedPackage)
        
        // Read back and verify replacement (order independent)
        let finalPackages = try PackageLocation.read(from: configPath.path)
        #expect(finalPackages.count == 2)
        let pkg1 = finalPackages.first { $0 == "/path/to/package1" }
        #expect(pkg1 != nil)
        let pkg2 = finalPackages.first { $0 == "/path/to/package2" }
        #expect(pkg2 != nil)
        
        // Clean up
        try FileManager.default.removeItem(atPath: configPath.path)
    }
    
    @Test("Read packages when file doesn't exist")
    func readPackagesWhenFileDoesntExist() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let configPath = tempDir.appendingPathComponent("non_existent_dir").path
        
        // Read packages from non-existent path
        let readPackages = try PackageLocation.read(from: configPath)
        
        // Should return empty array
        #expect(readPackages.isEmpty)
    }
    
    @Test("Update packages when file doesn't exist")
    func updatePackagesWhenFileDoesntExist() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let configPath = tempDir.appendingPathComponent("new_packages_dir").path
        
        // Update packages in non-existent directory
        let newPackage = "/path/to/package1"
        try PackageLocation.update(at: configPath, with: newPackage)
        
        // Verify the file was created and contains the package
        let readPackages = try PackageLocation.read(from: configPath)
        #expect(readPackages.count == 1)
        #expect(readPackages[0] == "/path/to/package1")
        
        // Clean up
        try FileManager.default.removeItem(atPath: configPath)
    }
    
    @Test("Plist format validation")
    func plistFormatValidation() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let configPath = tempDir.appendingPathComponent("test_plist_validation").path
        
        let packages = [
            "/path/to/package1",
            "/path/to/package2"
        ]
        
        // Write packages
        try PackageLocation.write(packages, to: configPath)
        
        // Read the raw plist content
        let expectedPackagesFile = URL(fileURLWithPath: configPath)
            .appendingPathComponent(".xcodecli")
            .appendingPathComponent("packages.plist")
        let plistContent = try String(contentsOf: expectedPackagesFile, encoding: .utf8)
        
        // Verify plist structure (array of strings)
        #expect(plistContent.contains("<array>"))
        #expect(plistContent.contains("<string>/path/to/package1</string>"))
        #expect(plistContent.contains("<string>/path/to/package2</string>"))
        
        // Clean up
        try FileManager.default.removeItem(atPath: configPath)
    }
} 
