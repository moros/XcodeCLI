import ArgumentParser
import CLI
import Foundation

/// The `delink` subcommand: removes a Swift package from the packages configuration.
struct DelinkCommand: ParsableCommand {
    
    static var configuration = CommandConfiguration(
        commandName: "delink",
        abstract: "Remove a Swift package from the packages configuration."
    )
    
    @OptionGroup var global: GlobalOptions
    
    @Argument(help: "Path to the package directory to remove (if omitted, the current directory is used).")
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
        
        print("Removing package at: \(resolvedPackagePath)")
        print("Configuration: \(finalConfigPath)")
        
        // Read existing packages
        let packages = try PackageLocation.read(from: finalConfigPath)
        
        // Check if the package exists in the configuration
        guard packages.contains(resolvedPackagePath) else {
            print("Package not found in configuration: \(resolvedPackagePath)")
            throw ExitCode.failure
        }
        
        // Remove the package from the list
        let updatedPackages = packages.filter { $0 != resolvedPackagePath }
        
        // Write the updated packages back to the configuration
        try PackageLocation.write(updatedPackages, to: finalConfigPath)
        
        print("Successfully removed package from packages configuration!")
    }
}
