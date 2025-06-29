import Foundation
import Testing
@testable import CLI

@Suite("Package Swift Parser Tests")
struct PackageSwiftParserTests {
    
    @Test("Parse package name")
    func parsePackageName() throws {
        let content = """
        // swift-tools-version: 5.9
        import PackageDescription
        
        let package = Package(
            name: "MyPackage",
            products: [
                .library(name: "MyLib", targets: ["MyLib"]),
            ],
            targets: [
                .target(name: "MyLib"),
            ]
        )
        """
        
        let packageInfo = try PackageSwiftParser.parsePackageSwiftContent(content)
        #expect(packageInfo.name == "MyPackage")
        #expect(packageInfo.libraries == ["MyLib"])
    }
    
    @Test("Parse package name with single quotes")
    func parsePackageNameWithSingleQuotes() throws {
        let content = """
        // swift-tools-version: 5.9
        import PackageDescription
        
        let package = Package(
            name: 'MyPackage',
            products: [
                .library(name: "MyLib", targets: ["MyLib"]),
            ],
            targets: [
                .target(name: "MyLib"),
            ]
        )
        """
        
        let packageInfo = try PackageSwiftParser.parsePackageSwiftContent(content)
        #expect(packageInfo.name == "MyPackage")
        #expect(packageInfo.libraries == ["MyLib"])
    }
    
    @Test("Parse multiple libraries")
    func parseMultipleLibraries() throws {
        let content = """
        // swift-tools-version: 5.9
        import PackageDescription
        
        let package = Package(
            name: "MyPackage",
            products: [
                .library(name: "MyLib", targets: ["MyLib"]),
                .library(name: "MyLibCore", targets: ["MyLibCore"]),
                .library(name: "MyLibUtils", targets: ["MyLibUtils"]),
            ],
            targets: [
                .target(name: "MyLib"),
                .target(name: "MyLibCore"),
                .target(name: "MyLibUtils"),
            ]
        )
        """
        
        let packageInfo = try PackageSwiftParser.parsePackageSwiftContent(content)
        #expect(packageInfo.name == "MyPackage")
        #expect(packageInfo.libraries == ["MyLib", "MyLibCore", "MyLibUtils"])
    }
    
    @Test("Parse library with different format")
    func parseLibraryWithDifferentFormat() throws {
        let content = """
        // swift-tools-version: 5.9
        import PackageDescription
        
        let package = Package(
            name: "MyPackage",
            products: [
                .library(
                    name: "MyLib",
                    targets: ["MyLib"]
                ),
            ],
            targets: [
                .target(name: "MyLib"),
            ]
        )
        """
        
        let packageInfo = try PackageSwiftParser.parsePackageSwiftContent(content)
        #expect(packageInfo.name == "MyPackage")
        #expect(packageInfo.libraries == ["MyLib"])
    }
    
    @Test("Missing name throws error")
    func missingNameThrowsError() throws {
        let content = """
        // swift-tools-version: 5.9
        import PackageDescription
        
        let package = Package(
            products: [
                .library(name: "MyLib", targets: ["MyLib"]),
            ],
            targets: [
                .target(name: "MyLib"),
            ]
        )
        """
        
        #expect(throws: PackageSwiftParser.ParseError.self) {
            try PackageSwiftParser.parsePackageSwiftContent(content)
        }
    }
    
    @Test("No libraries throws error")
    func noLibrariesThrowsError() throws {
        let content = """
        // swift-tools-version: 5.9
        import PackageDescription
        
        let package = Package(
            name: "MyPackage",
            products: [],
            targets: [
                .target(name: "MyLib"),
            ]
        )
        """
        
        #expect(throws: PackageSwiftParser.ParseError.self) {
            try PackageSwiftParser.parsePackageSwiftContent(content)
        }
    }
    
    @Test("Complex package structure")
    func complexPackageStructure() throws {
        let content = """
        // swift-tools-version: 5.9
        import PackageDescription
        
        let package = Package(
            name: "ComplexPackage",
            platforms: [
                .macOS(.v10_15),
                .iOS(.v13)
            ],
            products: [
                .library(
                    name: "CoreLibrary",
                    targets: ["CoreLibrary"]
                ),
                .library(
                    name: "UIComponents",
                    targets: ["UIComponents"]
                ),
                .executable(
                    name: "CLITool",
                    targets: ["CLITool"]
                )
            ],
            dependencies: [
                .package(url: "https://github.com/example/dependency", from: "1.0.0")
            ],
            targets: [
                .target(
                    name: "CoreLibrary",
                    dependencies: []
                ),
                .target(
                    name: "UIComponents",
                    dependencies: ["CoreLibrary"]
                ),
                .executableTarget(
                    name: "CLITool",
                    dependencies: ["CoreLibrary"]
                )
            ]
        )
        """
        
        let packageInfo = try PackageSwiftParser.parsePackageSwiftContent(content)
        #expect(packageInfo.name == "ComplexPackage")
        #expect(packageInfo.libraries == ["CoreLibrary", "UIComponents"])
    }
} 