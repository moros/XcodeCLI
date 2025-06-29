import ArgumentParser
import CLI
import Foundation
import PathKit
import XcodeProj

/// The `attach` subcommand: attaches packages into Xcode projects/workspaces.
struct AttachCommand: ParsableCommand {
    
    static var configuration = CommandConfiguration(
        commandName: "attach",
        abstract: "Attach packages into Xcode projects/workspaces."
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
        
        print("Attaching packages using config: \(configPath)")
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
                try attachPackages(in: xcodeProj, projectPath: resolvedPath, packages: packages, schemas: schemas)
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
                    try attachPackages(in: xcodeProj, projectPath: projPath, packages: packages, schemas: schemas)
                }
            } else {
                throw ValidationError("Path is neither a .xcodeproj nor a .xcworkspace: \(resolvedPath)")
            }
        } catch {
            print("Error: \(error.localizedDescription)")
            throw ExitCode.failure
        }
    }

    private func attachPackages(in xcodeProj: XcodeProj, projectPath: String, packages: [String], schemas: [PackageSchema]) throws {
        let pbxproj = xcodeProj.pbxproj
        guard let project = pbxproj.rootObject else {
            throw ValidationError("No root project found in pbxproj")
        }
        
        for (i, packagePath) in packages.enumerated() {
            let packageName: String
            //let expectedRepositoryURL: String?
            if i < schemas.count {
                packageName = schemas[i].name
                //expectedRepositoryURL = nil // We'll try to match by name, but fallback to path last component
            } else {
                packageName = URL(fileURLWithPath: packagePath).lastPathComponent
                //expectedRepositoryURL = nil
            }
            // Remove remote package reference if it exists
            if let remote = project.remotePackages.first(where: { ($0.name ?? "").localizedCaseInsensitiveContains(packageName) }) {
                // Save remote reference state before removing
                if let repoURL = remote.repositoryURL {
                    print("Saving remote package state for \(packageName) at \(repoURL)")
                    try? PackageStateManager.saveState(remote, forPackageName: packageName, expectedRepositoryURL: repoURL)
                }
                // Remove from remotePackages array
                project.remotePackages.removeAll { $0 == remote }
                // Remove from objects
                _ = pbxproj.objects.delete(reference: remote.reference)
                print("Removed remote package reference for \(packageName)")
            }
            
            // Check if a local reference for this package already exists to avoid duplicates
            let localPackages = project.localPackages
            let projDir = Path(projectPath).parent()
            let packagePathObj = Path(packagePath).normalize()  // absolute path to package
            let relativePath = packagePathObj.relative(to: projDir)
            if localPackages.contains(where: { ($0.name ?? "").localizedCaseInsensitiveContains(packageName) }) {
                print("Package \"\(packageName)\" is already attached locally. Skipping...")
            } else {
                // Create a new local Swift package reference using the project's method
                _ = try project.addLocalSwiftPackageReference(relativePath: relativePath.string)
                print("Attached local package \"\(packageName)\" at path: \(packagePath)")
            }

            // Add folder reference to project navigator (main group)
            let mainGroup = project.mainGroup!
            // Only add if not already present
            if mainGroup.file(named: packageName) == nil {
                _ = try? mainGroup.addFile(
                    at: packagePathObj,
                    sourceTree: .group,
                    sourceRoot: projDir,
                    override: false,
                    validatePresence: false // set to true if you want to check the path exists
                )
                print("Added folder reference for \"\(packageName)\" to project navigator.")
            }
        }
        
        try xcodeProj.writePBXProj(path: Path(projectPath), outputSettings: PBXOutputSettings())
        print("Successfully updated Xcode project with local package references.")
    }
} 
