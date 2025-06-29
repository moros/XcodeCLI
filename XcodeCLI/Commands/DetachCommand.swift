import ArgumentParser
import CLI
import Foundation
import PathKit
import XcodeProj

/// The `detach` subcommand: detaches packages from Xcode projects/workspaces.
struct DetachCommand: ParsableCommand {
    
    static var configuration = CommandConfiguration(
        commandName: "detach",
        abstract: "Detach packages from Xcode projects/workspaces."
    )
    
    @OptionGroup var global: GlobalOptions
    
    func run() throws {
        // Determine which configuration to use
        let cwd = global.getWorkingDirectory()
        let configPath: String
        if let configArg = global.config {
            configPath = NSString(string: configArg).expandingTildeInPath
        } else {
            configPath = cwd // Pass only the project root directory
        }
        
        print("Detaching packages using config: \(configPath)")
        PackageStateManager.setConfigRoot(configPath)
        do {
            // Load the configuration
            let commandConfig = try ConfigurationManager.readConfiguration(from: configPath)
            let packages = try PackageLocation.read(from: configPath)
            var schemas: [PackageSchema] = []
            for packagePath in packages {
                if let schema = try? PackageSchema.parseSchema(fromPath: packagePath) {
                    schemas.append(schema)
                }
            }
            
            // Determine Xcode project (or workspace) path
            let resolvedPath: String
            if let proj = commandConfig.project {
                resolvedPath = XcodeProjectFinder.resolveProjectPath(proj, relativeTo: cwd)
            } else if let workspace = commandConfig.workspace {
                resolvedPath = XcodeProjectFinder.resolveProjectPath(workspace, relativeTo: cwd)
            } else {
                resolvedPath = try XcodeProjectFinder.findXcodeProject(in: cwd)
            }
            
            print("Found Xcode project/workspace: \(resolvedPath)")
            
            let path = Path(resolvedPath)
            
            if resolvedPath.hasSuffix(".xcodeproj") {
                // Single project
                let xcodeProj = try XcodeProj(path: path)
                try detachPackages(in: xcodeProj, projectPath: resolvedPath, packages: packages, schemas: schemas)
            } else if resolvedPath.hasSuffix(".xcworkspace") {
                // Workspace: find all referenced .xcodeproj files
                let workspace = try XCWorkspace(path: path)
                let workspaceDir = path.parent()
                let projectPaths = workspace.data.children.compactMap { element -> String? in
                    switch element {
                    case .file(let ref):
                        let locationType = ref.location
                        let pathString = locationType.path
                        if pathString.hasSuffix(".xcodeproj") {
                            let projPath = Path(pathString)
                            // If the schema is "absolute", treat as absolute, otherwise relative to workspaceDir
                            if locationType.schema == "absolute" {
                                return projPath.string
                            } else {
                                return (workspaceDir + projPath).string
                            }
                        }
                    default:
                        break
                    }
                    return nil
                }
                for projPath in projectPaths {
                    print("Processing project in workspace: \(projPath)")
                    let xcodeProj = try XcodeProj(path: Path(projPath))
                    try detachPackages(in: xcodeProj, projectPath: projPath, packages: packages, schemas: schemas)
                }
            } else {
                throw ValidationError("Path is neither a .xcodeproj nor a .xcworkspace: \(resolvedPath)")
            }
        } catch {
            print("Error: \(error.localizedDescription)")
            throw ExitCode.failure
        }
    }

    private func detachPackages(in xcodeProj: XcodeProj, projectPath: String, packages: [String], schemas: [PackageSchema]) throws {
        let pbxproj = xcodeProj.pbxproj
        guard let project = pbxproj.rootObject else {
            throw ValidationError("No root project found in pbxproj")
        }
        
        for (i, packagePath) in packages.enumerated() {
            let packageName: String
            if i < schemas.count {
                packageName = schemas[i].name
            } else {
                packageName = URL(fileURLWithPath: packagePath).lastPathComponent
            }
            // Remove local package reference if it exists
            let localPackages = project.localPackages
            if let localPackage = localPackages.first(where: { ($0.name ?? "").localizedCaseInsensitiveContains(packageName) }) {
                // Remove from localPackages array
                project.localPackages.removeAll { $0 == localPackage }
                // Remove from objects
                _ = pbxproj.objects.delete(reference: localPackage.reference)
                print("Removed local package reference for \(packageName)")
                // Try to restore remote reference if state exists
                if let restoredRemote = try? PackageStateManager.loadAndRemoveState(forPackageName: packageName) {
                    print("Restoring remote package reference for \(packageName)")
                    print("Remote reference details: \(String(describing: restoredRemote))")
                    project.remotePackages.append(restoredRemote)
                    pbxproj.add(object: restoredRemote)
                    print("Restored remote package reference for \(packageName)")
                }
            } else {
                print("Local package reference for \"\(packageName)\" not found. Skipping...")
            }

            // Remove folder reference from project navigator (main group)
            let mainGroup = project.mainGroup!
            if let fileReference = mainGroup.file(named: packageName) {
                // Remove from group's children
                mainGroup.children.removeAll { $0 == fileReference }
                // Remove from objects
                _ = pbxproj.objects.delete(reference: fileReference.reference)
                print("Removed folder reference for \"\(packageName)\" from project navigator.")
            } else {
                print("Folder reference for \"\(packageName)\" not found in project navigator. Skipping...")
            }
        }
        
        try xcodeProj.writePBXProj(path: Path(projectPath), outputSettings: PBXOutputSettings())
        print("Successfully updated Xcode project by removing local package references.")
    }
} 
