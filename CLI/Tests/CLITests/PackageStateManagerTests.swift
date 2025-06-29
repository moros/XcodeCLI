import Foundation
import XcodeProj
@testable import CLI
import Testing

struct PackageStateManagerTests {
    
    @MainActor
    @Test
    func testSaveAndLoadState_createsFileAndRestoresReference() async throws {
        // Setup temp directory
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let packageName = "TestPackage"
        let repoURL = "https://example.com/repo.git"
        let versionRequirement = XCRemoteSwiftPackageReference.VersionRequirement.upToNextMajorVersion("1.2.3")
        let remote = XCRemoteSwiftPackageReference(repositoryURL: repoURL, versionRequirement: versionRequirement)

        // Set config root
        PackageStateManager.setConfigRoot(tempDir.path)

        // Save state
        try PackageStateManager.saveState(remote, forPackageName: packageName, expectedRepositoryURL: repoURL)

        // Check file exists
        let stateFilePath = PackageStateManager.getStateFilePath()
        #expect(FileManager.default.fileExists(atPath: stateFilePath))

        // Load and remove state
        let loaded = try PackageStateManager.loadAndRemoveState(forPackageName: packageName)
        #expect(loaded != nil)
        #expect(loaded?.repositoryURL == repoURL)
        if case let .upToNextMajorVersion(version)? = loaded?.versionRequirement {
            #expect(version == "1.2.3")
        } else {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Version requirement not restored correctly"])
        }

        // After removal, file should still exist but be empty for this package
        let loadedAgain = try PackageStateManager.loadAndRemoveState(forPackageName: packageName)
        #expect(loadedAgain == nil)
    }
} 
