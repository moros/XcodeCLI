import ArgumentParser
import CLI
import Foundation

/// The `init` subcommand: creates a .xcodecli directory with a config file inside it.
struct InitCommand: ParsableCommand {
    
    static var configuration = CommandConfiguration(
        commandName: "init",
        abstract: "Initialize a .xcodecli directory with a config file."
    )
    
    @OptionGroup var global: GlobalOptions
    
    @Option(name: [.long], help: "Path to the Xcode project file (.xcodeproj)")
    var project: String?
    
    @Option(name: [.long], help: "Path to the Xcode workspace file (.xcworkspace)")
    var workspace: String?
    
    func run() throws {
        let cwd = global.getWorkingDirectory()
        let configDirPath = ConfigurationManager.getConfigDirectoryPath(in: cwd)
        let configFilePath = ConfigurationManager.getConfigFilePath(in: cwd)
        
        let fileManager = FileManager.default
        let configDirExists = fileManager.fileExists(atPath: configDirPath)
        let configFileExists = fileManager.fileExists(atPath: configFilePath)
        
        // Check if both directory and config file exist
        if configDirExists && configFileExists {
            throw ValidationError("Both .xcodecli directory and config file already exist at: \(configDirPath)")
        }
        
        // Validate that only one of project or workspace is specified
        if project != nil && workspace != nil {
            throw ValidationError("Cannot specify both --project and --workspace. Please choose one.")
        }
        
        // Create directory if it doesn't exist
        if !configDirExists {
            do {
                try fileManager.createDirectory(atPath: configDirPath, withIntermediateDirectories: true)
            } catch {
                throw ValidationError("Failed to create .xcodecli directory: \(error.localizedDescription)")
            }
        }
        
        // Create configuration with project or workspace path
        let config = ProgramConfiguration(
            project: project,
            workspace: workspace
        )
        
        // Write configuration to file
        do {
            try ConfigurationManager.writeConfiguration(config, to: cwd)
        } catch {
            throw ValidationError("Failed to write configuration file: \(error.localizedDescription)")
        }
        
        print("Initialization completed successfully!")
        if let projectPath = project {
            print("Project path configured: \(projectPath)")
        } else if let workspacePath = workspace {
            print("Workspace path configured: \(workspacePath)")
        } else {
            print("No project or workspace specified. You can add one later using the configuration file.")
        }
    }
} 
