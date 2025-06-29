import ArgumentParser
import CLI
import Foundation

/// The `link` subcommand: adds a new Swift package by adding it to the packages file.
struct LinkCommand: ParsableCommand {
    
    static var configuration = CommandConfiguration(
        commandName: "link",
        abstract: "Add a Swift package to the packages configuration."
    )
    
    @OptionGroup var global: GlobalOptions
    
    @Argument(help: "Path to the package directory (if omitted, the current directory is used).")
    var packagePath: String?
    
    func run() throws {
        let cwd = global.getWorkingDirectory()
        // Determine package path and configuration path
        let resolvedPackagePath: String
        let finalConfigPath: String
        if let pkgPath = packagePath {
            // Path provided for the package
            resolvedPackagePath = NSString(string: pkgPath).expandingTildeInPath
            // Use provided config or default to .xcodecli directory in CWD
            if let configArg = global.config {
                finalConfigPath = NSString(string: configArg).expandingTildeInPath
            } else {
                finalConfigPath = cwd // Pass only the project root directory
            }
        } else {
            // No package path provided: use current directory for package
            resolvedPackagePath = cwd
            // In this case, --config is required
            guard let configArg = global.config else {
                throw ValidationError("Missing required --config when no package path is provided.")
            }
            finalConfigPath = NSString(string: configArg).expandingTildeInPath
        }
        
        print("Tracking package at: \(resolvedPackagePath)")
        print("Configuration: \(finalConfigPath)")
        // Parse Package.swift to get package name and library products
        let packageInfo = try PackageSwiftParser.parsePackageSwift(at: resolvedPackagePath)
        print("Package name: \(packageInfo.name)")
        print("Libraries found: \(packageInfo.libraries.joined(separator: ", "))")
        
        // Add the new package path to the packages configuration
        try PackageLocation.update(at: finalConfigPath, with: resolvedPackagePath)
        
        print("Successfully added package to packages configuration!")
    }
} 
