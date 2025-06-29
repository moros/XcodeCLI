import ArgumentParser
import CLI
import Foundation
import PathKit
import XcodeProj

/// Global options shared by commands (currently only the config file path).
struct GlobalOptions: ParsableArguments {
    @Option(name: [.short, .long], help: "Path to the configuration file (defaults to .xcodecli directory in the current directory).")
    var config: String?
    
    @Option(name: [.short, .long], help: "Working directory (defaults to current directory).")
    var workdir: String?
    
    /// Get the working directory to use for this command
    func getWorkingDirectory() -> String {
        if let workdir = workdir {
            return NSString(string: workdir).expandingTildeInPath
        } else {
            return FileManager.default.currentDirectoryPath
        }
    }
}

struct XcodeProjCLI: ParsableCommand {
    
    static var configuration = CommandConfiguration(
        commandName: "xc",
        abstract: "XcodeProj CLI tool",
        discussion: """
        """,
        subcommands: [InitCommand.self, LinkCommand.self, DelinkCommand.self, AttachCommand.self, DetachCommand.self],
        defaultSubcommand: nil
    )
    
    @OptionGroup var global: GlobalOptions
    
    func run() throws {
        // Determine which config file to use (provided or default to .xcodecli directory in CWD)
        let configPath: String
        if let configArg = global.config {
            configPath = NSString(string: configArg).expandingTildeInPath
        } else {
            let cwd = global.getWorkingDirectory()
            configPath = cwd // Pass only the project root directory
        }
        
        print("Using configuration: \(configPath)")
        do {
            // Parse and load the configuration file
            let commandConfig = try ConfigurationManager.readConfiguration(from: configPath)
            
            // Show project/workspace info
            print("\nXcode Project/Workspace:")
            print("------------------------")
            let cwd = global.getWorkingDirectory()
            if let projectPath = commandConfig.project {
                let resolved = XcodeProjectFinder.resolveProjectPath(projectPath, relativeTo: cwd)
                print("Project: \(resolved)")
            } else if let workspacePath = commandConfig.workspace {
                let resolved = XcodeProjectFinder.resolveProjectPath(workspacePath, relativeTo: cwd)
                print("Workspace: \(resolved)")
            } else {
                // Auto-discover if none specified
                do {
                    let discovered = try XcodeProjectFinder.findXcodeProject(in: cwd)
                    print("Auto-discovered: \(discovered)")
                } catch {
                    print("Auto-discovery failed: \(error.localizedDescription)")
                }
            }
            
            // Load and display package configurations
            let packages = try PackageLocation.read(from: configPath)
            var schemas: [PackageSchema] = []
            for packagePath in packages {
                if let schema = try? PackageSchema.parseSchema(fromPath: packagePath) {
                    schemas.append(schema)
                }
            }
            print("\nPackage Configurations (\(packages.count)):")
            print("----------------------------------------")
            for (index, schema) in schemas.enumerated() {
                print("\(index + 1). name: \(schema.name), products: \(schema.products.map { $0.name }.joined(separator: ", "))")
                print()  // blank line between entries
            }
        } catch {
            print("Error parsing configuration: \(error.localizedDescription)")
            print("Tried to read from: \(configPath)")
            throw ExitCode.failure  // Return a failure exit code
        }
    }
}

XcodeProjCLI.main()
