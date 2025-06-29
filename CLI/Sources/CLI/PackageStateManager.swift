import Foundation
import AEXML
import XcodeProj

public class PackageStateManager {
    public static let stateFileName = "package_states.xml"
    public static let stateDirectoryName = ".xcodecli"
    nonisolated(unsafe) private static var configRoot: String = FileManager.default.currentDirectoryPath

    /// Set the config root directory (should be called at CLI startup)
    public static func setConfigRoot(_ root: String) {
        configRoot = root
    }

    /// Get the full path to the state file
    public static func getStateFilePath() -> String {
        return URL(fileURLWithPath: configRoot)
            .appendingPathComponent(stateDirectoryName)
            .appendingPathComponent(stateFileName)
            .path
    }

    /// Save a remote package reference for a package name, only if the repositoryURL matches
    public static func saveState(_ reference: XCRemoteSwiftPackageReference, forPackageName packageName: String, expectedRepositoryURL: String) throws {
        guard let repoURL = reference.repositoryURL, repoURL == expectedRepositoryURL else {
            print("[PackageStateManager] Skipping save: repositoryURL mismatch for package \(packageName)")
            return
        }
        let stateFilePath = getStateFilePath()
        let stateDir = URL(fileURLWithPath: configRoot).appendingPathComponent(stateDirectoryName).path
        if !FileManager.default.fileExists(atPath: stateDir) {
            try FileManager.default.createDirectory(atPath: stateDir, withIntermediateDirectories: true)
        }
        var document: AEXMLDocument

        if FileManager.default.fileExists(atPath: stateFilePath) {
            let data = try Data(contentsOf: URL(fileURLWithPath: stateFilePath))
            document = try AEXMLDocument(xml: data)
        } else {
            document = AEXMLDocument()
            document.addChild(name: "PackageStates")
        }

        // Remove any existing entry for this package
        document.root["Package"].all(withAttributes: ["name": packageName])?.forEach { $0.removeFromParent() }

        let packageElement = document.root.addChild(name: "Package", attributes: ["name": packageName])
        packageElement.addChild(name: "repositoryURL", value: repoURL)
        if let requirement = reference.versionRequirement {
            let reqElement = packageElement.addChild(name: "versionRequirement")
            switch requirement {
            case .upToNextMajorVersion(let version):
                reqElement.addChild(name: "kind", value: "upToNextMajorVersion")
                reqElement.addChild(name: "minimumVersion", value: version)
            case .upToNextMinorVersion(let version):
                reqElement.addChild(name: "kind", value: "upToNextMinorVersion")
                reqElement.addChild(name: "minimumVersion", value: version)
            case .range(let from, let to):
                reqElement.addChild(name: "kind", value: "range")
                reqElement.addChild(name: "minimumVersion", value: from)
                reqElement.addChild(name: "maximumVersion", value: to)
            case .exact(let version):
                reqElement.addChild(name: "kind", value: "exact")
                reqElement.addChild(name: "version", value: version)
            case .branch(let branch):
                reqElement.addChild(name: "kind", value: "branch")
                reqElement.addChild(name: "branch", value: branch)
            case .revision(let revision):
                reqElement.addChild(name: "kind", value: "revision")
                reqElement.addChild(name: "revision", value: revision)
            }
        }

        let xmlData = document.xml.data(using: .utf8)!
        try xmlData.write(to: URL(fileURLWithPath: stateFilePath))
    }

    /// Load and remove a remote package reference for a package name
    public static func loadAndRemoveState(forPackageName packageName: String) throws -> XCRemoteSwiftPackageReference? {
        let stateFilePath = getStateFilePath()
        guard FileManager.default.fileExists(atPath: stateFilePath) else { return nil }

        let data = try Data(contentsOf: URL(fileURLWithPath: stateFilePath))
        let document = try AEXMLDocument(xml: data)

        guard let packageElement = document.root["Package"].all(withAttributes: ["name": packageName])?.first else {
            return nil
        }

        guard let repoURL = packageElement["repositoryURL"].value else { return nil }
        var versionRequirement: XCRemoteSwiftPackageReference.VersionRequirement? = nil
        if let reqElement = packageElement["versionRequirement"].first {
            let kind = reqElement["kind"].string
            switch kind {
            case "upToNextMajorVersion":
                versionRequirement = .upToNextMajorVersion(reqElement["minimumVersion"].string)
            case "upToNextMinorVersion":
                versionRequirement = .upToNextMinorVersion(reqElement["minimumVersion"].string)
            case "range":
                versionRequirement = .range(from: reqElement["minimumVersion"].string, to: reqElement["maximumVersion"].string)
            case "exact":
                versionRequirement = .exact(reqElement["version"].string)
            case "branch":
                versionRequirement = .branch(reqElement["branch"].string)
            case "revision":
                versionRequirement = .revision(reqElement["revision"].string)
            default:
                break
            }
        }

        // Remove the entry
        packageElement.removeFromParent()

        // Save the updated XML
        let xmlData = document.xml.data(using: .utf8)!
        try xmlData.write(to: URL(fileURLWithPath: stateFilePath))

        return XCRemoteSwiftPackageReference(repositoryURL: repoURL, versionRequirement: versionRequirement)
    }
} 
