import Foundation
import PathKit

public final class PBXProject: PBXObject {
    // MARK: - Attributes

    /// Project name
    public var name: String

    /// Build configuration list reference.
    var buildConfigurationListReference: PBXObjectReference

    /// Build configuration list.
    public var buildConfigurationList: XCConfigurationList! {
        set {
            buildConfigurationListReference = newValue.reference
        }
        get {
            buildConfigurationListReference.getObject()
        }
    }

    /// A string representation of the XcodeCompatibilityVersion.
    public var compatibilityVersion: String?

    /// An int representation of the PreferredProjectObjectVersion.
    public var preferredProjectObjectVersion: Int?

    /// An int representation of the minimizedProjectReferenceProxies attribute
    public var minimizedProjectReferenceProxies: Int?

    /// The region of development.
    public var developmentRegion: String?

    /// Whether file encodings have been scanned.
    public var hasScannedForEncodings: Int

    /// The known regions for localized files.
    public var knownRegions: [String]

    /// The object is a reference to a PBXGroup element.
    var mainGroupReference: PBXObjectReference

    /// Project main group.
    public var mainGroup: PBXGroup! {
        set {
            mainGroupReference = newValue.reference
        }
        get {
            mainGroupReference.getObject()
        }
    }

    /// The object is a reference to a PBXGroup element.
    var productsGroupReference: PBXObjectReference?

    /// Products group.
    public var productsGroup: PBXGroup? {
        set {
            productsGroupReference = newValue?.reference
        }
        get {
            productsGroupReference?.getObject()
        }
    }

    /// The relative path of the project.
    public var projectDirPath: String

    /// Project references.
    var projectReferences: [[String: PBXObjectReference]]

    /// Project projects.
    //    {
    //        ProductGroup = B900DB69213936CC004AEC3E /* Products group reference */;
    //        ProjectRef = B900DB68213936CC004AEC3E /* Project file reference  */;
    //    },
    public var projects: [[String: PBXFileElement]] {
        set {
            projectReferences = newValue.map { project in
                project.mapValues { $0.reference }
            }
        }
        get {
            projectReferences.map { project in
                project.mapValues { $0.getObject()! }
            }
        }
    }

    private static let targetAttributesKey = "TargetAttributes"

    /// The relative root paths of the project.
    public var projectRoots: [String]

    /// The objects are a reference to a PBXTarget element.
    var targetReferences: [PBXObjectReference]

    /// Project targets.
    public var targets: [PBXTarget] {
        set {
            targetReferences = newValue.references()
        }
        get {
            targetReferences.objects()
        }
    }

    /// Project attributes.
    /// Target attributes will be merged into this
    public var attributes: [String: ProjectAttribute]

    /// Target attribute references.
    var targetAttributeReferences: [PBXObjectReference: [String: ProjectAttribute]]

    /// Target attributes.
    public var targetAttributes: [PBXTarget: [String: ProjectAttribute]] {
        set {
            targetAttributeReferences = [:]
            for item in newValue {
                targetAttributeReferences[item.key.reference] = item.value
            }
        } get {
            var attributes: [PBXTarget: [String: ProjectAttribute]] = [:]
            for targetAttributeReference in targetAttributeReferences {
                if let object: PBXTarget = targetAttributeReference.key.getObject() {
                    attributes[object] = targetAttributeReference.value
                }
            }
            return attributes
        }
    }

    /// Remote (`XCRemoteSwiftPackageReference`) and Local (`XCLocalSwiftPackageReference`) Package references.
    public var packageReferences: [PBXObjectReference]?

    /// Remote Swift packages.
    @available(*, deprecated, message: "use remotePackages or localPackages.")
    public var packages: [XCRemoteSwiftPackageReference] {
        remotePackages
    }

    /// Remote Swift packages.
    public var remotePackages: [XCRemoteSwiftPackageReference] {
        set {
            setPackageReferences(newValue)
        }
        get {
            packageReferences?.objects() ?? []
        }
    }

    /// Local Swift packages.
    public var localPackages: [XCLocalSwiftPackageReference] {
        set {
            setPackageReferences(newValue)
        }
        get {
            packageReferences?.compactMap { $0.getObject() } ?? []
        }
    }

    private func setPackageReferences<T: PBXContainerItem>(_ packages: [T]) {
        let newReferences = packages.references()
        var finalReferences: [PBXObjectReference] = packageReferences?.filter { !($0.getObject() is T) } ?? []
        for reference in newReferences {
            if !finalReferences.contains(reference) {
                finalReferences.append(reference)
            }
        }
        packageReferences = finalReferences
    }

    /// Sets the attributes for the given target.
    ///
    /// - Parameters:
    ///   - attributes: attributes that will be set.
    ///   - target: target.
    public func setTargetAttributes(_ attributes: [String: ProjectAttribute], target: PBXTarget) {
        targetAttributeReferences[target.reference] = attributes
    }

    /// Removes the attributes for the given target.
    ///
    /// - Parameter target: target whose attributes will be removed.
    public func removeTargetAttributes(target: PBXTarget) {
        targetAttributeReferences.removeValue(forKey: target.reference)
    }

    /// Removes the all the target attributes
    public func clearAllTargetAttributes() {
        targetAttributeReferences.removeAll()
    }

    /// Returns the attributes of a given target.
    ///
    /// - Parameter for: target whose attributes will be returned.
    /// - Returns: target attributes.
    public func attributes(for target: PBXTarget) -> [String: Any]? {
        targetAttributeReferences[target.reference]
    }

    /// Adds a remote swift package
    ///
    /// - Parameters:
    ///   - repositoryURL: URL in String pointing to the location of remote Swift package
    ///   - productName: The product to depend on without the extension
    ///   - versionRequirement: Describes the rules of the version to use
    ///   - targetName: Target's name to link package product to
    public func addSwiftPackage(repositoryURL: String,
                                productName: String,
                                versionRequirement: XCRemoteSwiftPackageReference.VersionRequirement,
                                targetName: String) throws -> XCRemoteSwiftPackageReference {
        let objects = try objects()

        guard let target = targets.first(where: { $0.name == targetName }) else { throw PBXProjError.targetNotFound(targetName: targetName) }

        // Reference
        let reference = try addSwiftPackageReference(repositoryURL: repositoryURL,
                                                     productName: productName,
                                                     versionRequirement: versionRequirement)

        // Product
        let productDependency = try addSwiftPackageProduct(reference: reference,
                                                           productName: productName,
                                                           target: target)

        // Build file
        let buildFile = PBXBuildFile(product: productDependency)
        objects.add(object: buildFile)

        // Link the product
        guard let frameworksBuildPhase = try target.frameworksBuildPhase() else { throw PBXProjError.frameworksBuildPhaseNotFound(targetName: targetName) }
        frameworksBuildPhase.files?.append(buildFile)

        return reference
    }

    /// Adds a local swift package
    ///
    /// - Parameters:
    ///   - path: Relative path to the swift package (throws an error if the path is absolute)
    ///   - productName: The product to depend on without the extension
    ///   - targetName: Target's name to link package product to
    ///   - addFileReference: Include a file reference to the package (defaults to main group)
    public func addLocalSwiftPackage(path: Path,
                                     productName: String,
                                     targetName: String,
                                     addFileReference: Bool = true) throws -> XCSwiftPackageProductDependency {
        guard path.isRelative else { throw PBXProjError.pathIsAbsolute(path) }

        let objects = try objects()

        guard let target = targets.first(where: { $0.name == targetName }) else { throw PBXProjError.targetNotFound(targetName: targetName) }

        // Product
        let productDependency = try addLocalSwiftPackageProduct(path: path,
                                                                productName: productName,
                                                                target: target)

        // Build file
        let buildFile = PBXBuildFile(product: productDependency)
        objects.add(object: buildFile)

        // Link the product
        guard let frameworksBuildPhase = try target.frameworksBuildPhase() else {
            throw PBXProjError.frameworksBuildPhaseNotFound(targetName: targetName)
        }

        frameworksBuildPhase.files?.append(buildFile)

        // File reference
        // The user might want to control adding the file's reference (to be exact when the reference is added)
        // to achieve desired hierarchy of the group's children
        if addFileReference {
            let reference = PBXFileReference(sourceTree: .group,
                                             name: productName,
                                             lastKnownFileType: "folder",
                                             path: path.string)
            objects.add(object: reference)
            mainGroup.children.append(reference)
        }

        return productDependency
    }

    /// Adds a local Swift package reference directly to the project
    ///
    /// - Parameter relativePath: Relative path to the Swift package
    /// - Returns: The created local Swift package reference
    public func addLocalSwiftPackageReference(relativePath: String) throws -> XCLocalSwiftPackageReference {
        let objects = try objects()
        
        // Check if package already exists
        if let existingPackage = localPackages.first(where: { $0.relativePath == relativePath }) {
            return existingPackage
        }
        
        let packageReference = XCLocalSwiftPackageReference(relativePath: relativePath)
        objects.add(object: packageReference)
        localPackages.append(packageReference)
        
        return packageReference
    }

    /// Adds a remote Swift package reference directly to the project
    ///
    /// - Parameters:
    ///   - repositoryURL: URL pointing to the remote Swift package
    ///   - versionRequirement: Version requirement for the package
    /// - Returns: The created remote Swift package reference
    public func addRemoteSwiftPackageReference(repositoryURL: String, versionRequirement: XCRemoteSwiftPackageReference.VersionRequirement) throws -> XCRemoteSwiftPackageReference {
        let objects = try objects()
        
        // Check if package already exists
        if let existingPackage = remotePackages.first(where: { $0.repositoryURL == repositoryURL }) {
            guard existingPackage.versionRequirement == versionRequirement else {
                throw PBXProjError.multipleRemotePackages(productName: existingPackage.name ?? "unknown")
            }
            return existingPackage
        }
        
        let packageReference = XCRemoteSwiftPackageReference(repositoryURL: repositoryURL, versionRequirement: versionRequirement)
        objects.add(object: packageReference)
        remotePackages.append(packageReference)
        
        return packageReference
    }

    /// Adds a Swift package product dependency to a target
    ///
    /// - Parameters:
    ///   - productName: Name of the product to depend on
    ///   - package: Optional remote package reference (nil for local packages)
    ///   - targetName: Name of the target to add the dependency to
    /// - Returns: The created Swift package product dependency
    public func addSwiftPackageProductDependency(productName: String, package: XCRemoteSwiftPackageReference? = nil, targetName: String) throws -> XCSwiftPackageProductDependency {
        let objects = try objects()
        
        guard let target = targets.first(where: { $0.name == targetName }) else { 
            throw PBXProjError.targetNotFound(targetName: targetName) 
        }
        
        let productDependency = XCSwiftPackageProductDependency(productName: productName, package: package)
        objects.add(object: productDependency)
        
        if target.packageProductDependencies == nil {
            target.packageProductDependencies = []
        }
        target.packageProductDependencies?.append(productDependency)
        
        return productDependency
    }

    /// Adds a build file for a Swift package product dependency to a target's frameworks build phase
    ///
    /// - Parameters:
    ///   - productDependency: The Swift package product dependency
    ///   - targetName: Name of the target to add the build file to
    /// - Returns: The created build file
    public func addSwiftPackageBuildFile(productDependency: XCSwiftPackageProductDependency, targetName: String) throws -> PBXBuildFile {
        let objects = try objects()
        
        guard let target = targets.first(where: { $0.name == targetName }) else { 
            throw PBXProjError.targetNotFound(targetName: targetName) 
        }
        
        guard let frameworksBuildPhase = try target.frameworksBuildPhase() else {
            throw PBXProjError.frameworksBuildPhaseNotFound(targetName: targetName)
        }
        
        let buildFile = PBXBuildFile(product: productDependency)
        objects.add(object: buildFile)
        
        if frameworksBuildPhase.files == nil {
            frameworksBuildPhase.files = []
        }
        frameworksBuildPhase.files?.append(buildFile)
        
        return buildFile
    }

    // MARK: - Init

    /// Initializes the project with its attributes
    ///
    /// - Parameters:
    ///   - name: xcodeproj's name.
    ///   - buildConfigurationList: project build configuration list.
    ///   - compatibilityVersion: project compatibility version.
    ///   - preferredProjectObjectVersion: preferred project object version
    ///   - minimizedProjectReferenceProxies: minimized project reference proxies
    ///   - mainGroup: project main group.
    ///   - developmentRegion: project has development region.
    ///   - hasScannedForEncodings: project has scanned for encodings.
    ///   - knownRegions: project known regions.
    ///   - productsGroup: products group.
    ///   - projectDirPath: project dir path.
    ///   - projects: projects.
    ///   - projectRoots: project roots.
    ///   - targets: project targets.
    ///   - packages: project's remote packages.
    ///   - attributes: project's attributes.
    ///   - targetAttributes: project target's attributes.
    public init(name: String,
                buildConfigurationList: XCConfigurationList,
                compatibilityVersion: String?,
                preferredProjectObjectVersion: Int?,
                minimizedProjectReferenceProxies: Int?,
                mainGroup: PBXGroup,
                developmentRegion: String? = nil,
                hasScannedForEncodings: Int = 0,
                knownRegions: [String] = [],
                productsGroup: PBXGroup? = nil,
                projectDirPath: String = "",
                projects: [[String: PBXFileElement]] = [],
                projectRoots: [String] = [],
                targets: [PBXTarget] = [],
                packages: [XCRemoteSwiftPackageReference] = [],
                attributes: [String: ProjectAttribute] = [:],
                targetAttributes: [PBXTarget: [String: ProjectAttribute]] = [:]) {
        self.name = name
        buildConfigurationListReference = buildConfigurationList.reference
        self.compatibilityVersion = compatibilityVersion
        self.preferredProjectObjectVersion = preferredProjectObjectVersion
        self.minimizedProjectReferenceProxies = minimizedProjectReferenceProxies
        mainGroupReference = mainGroup.reference
        self.developmentRegion = developmentRegion
        self.hasScannedForEncodings = hasScannedForEncodings
        self.knownRegions = knownRegions
        productsGroupReference = productsGroup?.reference
        self.projectDirPath = projectDirPath
        projectReferences = projects.map { project in project.mapValues { $0.reference } }
        self.projectRoots = projectRoots
        targetReferences = targets.references()
        packageReferences = packages.references()
        self.attributes = attributes
        targetAttributeReferences = [:]
        super.init()
        self.targetAttributes = targetAttributes
    }

    // MARK: - Decodable

    fileprivate enum CodingKeys: String, CodingKey {
        case name
        case buildConfigurationList
        case compatibilityVersion
        case preferredProjectObjectVersion
        case minimizedProjectReferenceProxies
        case developmentRegion
        case hasScannedForEncodings
        case knownRegions
        case mainGroup
        case productRefGroup
        case projectDirPath
        case projectReferences
        case projectRoot
        case projectRoots
        case targets
        case attributes
        case packageReferences
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let referenceRepository = decoder.context.objectReferenceRepository
        let objects = decoder.context.objects
        name = try (container.decodeIfPresent(.name)) ?? ""
        let buildConfigurationListReference: String = try container.decode(.buildConfigurationList)
        self.buildConfigurationListReference = referenceRepository.getOrCreate(reference: buildConfigurationListReference, objects: objects)
        compatibilityVersion = try container.decodeIfPresent(.compatibilityVersion)
        preferredProjectObjectVersion = if let stringValue = try container.decodeIfPresent(String.self, forKey: .preferredProjectObjectVersion) {
            Int(stringValue)
        } else if let intValue = try container.decodeIfPresent(Int.self, forKey: .preferredProjectObjectVersion) {
            intValue
        } else {
            nil
        }
        minimizedProjectReferenceProxies = if let stringValue = try container.decodeIfPresent(String.self, forKey: .minimizedProjectReferenceProxies) {
            Int(stringValue)
        } else if let intValue = try container.decodeIfPresent(Int.self, forKey: .minimizedProjectReferenceProxies) {
            intValue
        } else {
            nil
        }
        developmentRegion = try container.decodeIfPresent(.developmentRegion)
        let hasScannedForEncodingsString: String? = try container.decodeIfPresent(.hasScannedForEncodings)
        hasScannedForEncodings = hasScannedForEncodingsString.flatMap { Int($0) } ?? 0
        knownRegions = try (container.decodeIfPresent(.knownRegions)) ?? []
        let mainGroupReference: String = try container.decode(.mainGroup)
        self.mainGroupReference = referenceRepository.getOrCreate(reference: mainGroupReference, objects: objects)
        if let productRefGroupReference: String = try container.decodeIfPresent(.productRefGroup) {
            productsGroupReference = referenceRepository.getOrCreate(reference: productRefGroupReference, objects: objects)
        } else {
            productsGroupReference = nil
        }
        projectDirPath = try container.decodeIfPresent(.projectDirPath) ?? ""
        let projectReferences: [[String: String]] = try (container.decodeIfPresent(.projectReferences)) ?? []
        self.projectReferences = projectReferences.map { references in
            references.mapValues { referenceRepository.getOrCreate(reference: $0, objects: objects) }
        }
        if let projectRoots: [String] = try container.decodeIfPresent(.projectRoots) {
            self.projectRoots = projectRoots
        } else if let projectRoot: String = try container.decodeIfPresent(.projectRoot) {
            projectRoots = [projectRoot]
        } else {
            projectRoots = []
        }
        let targetReferences: [String] = try (container.decodeIfPresent(.targets)) ?? []
        self.targetReferences = targetReferences.map { referenceRepository.getOrCreate(reference: $0, objects: objects) }

        let packageRefeferenceStrings: [String] = try container.decodeIfPresent(.packageReferences) ?? []
        packageReferences = packageRefeferenceStrings.map { referenceRepository.getOrCreate(reference: $0, objects: objects) }

        var attributes = try (container.decodeIfPresent([String: ProjectAttribute].self, forKey: .attributes) ?? [:])
        var targetAttributeReferences: [PBXObjectReference: [String: ProjectAttribute]] = [:]
        if case let .attributeDictionary(targetAttributes) = attributes[PBXProject.targetAttributesKey] {
            for targetAttribute in targetAttributes {
                targetAttributeReferences[referenceRepository.getOrCreate(reference: targetAttribute.key, objects: objects)] = targetAttribute.value
            }
            attributes[PBXProject.targetAttributesKey] = nil
        }
        self.attributes = attributes
        self.targetAttributeReferences = targetAttributeReferences

        try super.init(from: decoder)
    }

    override func isEqual(to object: Any?) -> Bool {
        guard let rhs = object as? PBXProject else { return false }
        return isEqual(to: rhs)
    }
}

// MARK: - Helpers

extension PBXProject {
    /// Adds reference for remote Swift package
    private func addSwiftPackageReference(repositoryURL: String,
                                          productName: String,
                                          versionRequirement: XCRemoteSwiftPackageReference.VersionRequirement) throws -> XCRemoteSwiftPackageReference {
        let reference: XCRemoteSwiftPackageReference
        if let package = remotePackages.first(where: { $0.repositoryURL == repositoryURL }) {
            guard package.versionRequirement == versionRequirement else {
                throw PBXProjError.multipleRemotePackages(productName: productName)
            }
            reference = package
        } else {
            reference = XCRemoteSwiftPackageReference(repositoryURL: repositoryURL, versionRequirement: versionRequirement)
            try objects().add(object: reference)
            remotePackages.append(reference)
        }

        return reference
    }

    /// Adds package product for remote Swift package
    private func addSwiftPackageProduct(reference: XCRemoteSwiftPackageReference,
                                        productName: String,
                                        target: PBXTarget) throws -> XCSwiftPackageProductDependency {
        let objects = try objects()

        let productDependency: XCSwiftPackageProductDependency
        // Avoid duplication
        if let product = objects.swiftPackageProductDependencies.first(where: { $0.value.package == reference && $0.value.productName == productName })?.value {
            productDependency = product
        } else {
            productDependency = XCSwiftPackageProductDependency(productName: productName, package: reference)
            objects.add(object: productDependency)
        }
        target.packageProductDependencies?.append(productDependency)

        return productDependency
    }

    /// Adds package product for local Swift package
    private func addLocalSwiftPackageProduct(path: Path,
                                             productName: String,
                                             target: PBXTarget) throws -> XCSwiftPackageProductDependency {
        let objects = try objects()

        let productDependency: XCSwiftPackageProductDependency
        // Avoid duplication
        if let product = objects.swiftPackageProductDependencies.first(where: { $0.value.productName == productName }) {
            guard objects.fileReferences.first(where: { $0.value.name == productName })?.value.path == path.string else {
                throw PBXProjError.multipleLocalPackages(productName: productName)
            }
            productDependency = product.value
        } else {
            productDependency = XCSwiftPackageProductDependency(productName: productName)
            objects.add(object: productDependency)
        }
        target.packageProductDependencies?.append(productDependency)

        return productDependency
    }
}

// MARK: - PlistSerializable

extension PBXProject: PlistSerializable {
    // swiftlint:disable:next function_body_length
    func plistKeyAndValue(proj: PBXProj, reference: String) throws -> (key: CommentedString, value: PlistValue) {
        var dictionary: [CommentedString: PlistValue] = [:]
        dictionary["isa"] = .string(CommentedString(PBXProject.isa))
        let buildConfigurationListComment = "Build configuration list for PBXProject \"\(name)\""
        let buildConfigurationListCommentedString = CommentedString(buildConfigurationListReference.value,
                                                                    comment: buildConfigurationListComment)
        dictionary["buildConfigurationList"] = .string(buildConfigurationListCommentedString)
        if let compatibilityVersion {
            dictionary["compatibilityVersion"] = .string(CommentedString(compatibilityVersion))
        }
        if let developmentRegion {
            dictionary["developmentRegion"] = .string(CommentedString(developmentRegion))
        }
        dictionary["hasScannedForEncodings"] = .string(CommentedString("\(hasScannedForEncodings)"))

        if !knownRegions.isEmpty {
            dictionary["knownRegions"] = PlistValue.array(knownRegions
                .map { .string(CommentedString("\($0)")) })
        }
        let mainGroupObject: PBXGroup? = mainGroupReference.getObject()
        dictionary["mainGroup"] = .string(CommentedString(mainGroupReference.value, comment: mainGroupObject?.fileName()))
        if let preferredProjectObjectVersion {
            dictionary["preferredProjectObjectVersion"] = .string(CommentedString(preferredProjectObjectVersion.description))
        }
        if let minimizedProjectReferenceProxies {
            dictionary["minimizedProjectReferenceProxies"] = .string(CommentedString(minimizedProjectReferenceProxies.description))
        }
        if let productsGroupReference {
            let productRefGroupObject: PBXGroup? = productsGroupReference.getObject()
            dictionary["productRefGroup"] = .string(CommentedString(productsGroupReference.value,
                                                                    comment: productRefGroupObject?.fileName()))
        }
        dictionary["projectDirPath"] = .string(CommentedString(projectDirPath))
        if projectRoots.count > 1 {
            dictionary["projectRoots"] = projectRoots.plist()
        } else {
            dictionary["projectRoot"] = .string(CommentedString(projectRoots.first ?? ""))
        }
        if let projectReferences = try projectReferencesPlistValue(proj: proj) {
            dictionary["projectReferences"] = projectReferences
        }
        dictionary["targets"] = PlistValue.array(targetReferences
            .map { targetReference in
                let target: PBXTarget? = targetReference.getObject()
                return .string(CommentedString(targetReference.value, comment: target?.name))
            })

        if !remotePackages.isEmpty || !localPackages.isEmpty {
            let remotePackageReferences = remotePackages.map {
                PlistValue.string(CommentedString($0.reference.value, comment: "XCRemoteSwiftPackageReference \"\($0.name ?? "")\""))
            }
            let localPackageReferences = localPackages.map {
                PlistValue.string(CommentedString($0.reference.value, comment: "XCLocalSwiftPackageReference \"\($0.name ?? "")\""))
            }
            var finalPackageReferences = remotePackageReferences
            finalPackageReferences.append(contentsOf: localPackageReferences)
            dictionary["packageReferences"] = PlistValue.array(finalPackageReferences)
        }

        var plistAttributes: [String: ProjectAttribute] = attributes

        // merge target attributes
        var plistTargetAttributes: [String: [String: ProjectAttribute]] = [:]
        for (reference, value) in targetAttributeReferences {
            plistTargetAttributes[reference.value] = value
        }

        plistAttributes[PBXProject.targetAttributesKey] = .attributeDictionary(plistTargetAttributes)

        dictionary["attributes"] = plistAttributes.plist()

        return (key: CommentedString(reference,
                                     comment: "Project object"),
                value: .dictionary(dictionary))
    }

    private func projectReferencesPlistValue(proj _: PBXProj) throws -> PlistValue? {
        guard !projectReferences.isEmpty else {
            return nil
        }
        return .array(projectReferences.compactMap { reference in
            guard let productGroupReference = reference[Xcode.ProjectReference.productGroupKey],
                  let projectRef = reference[Xcode.ProjectReference.projectReferenceKey]
            else {
                return nil
            }
            let producGroup: PBXGroup? = productGroupReference.getObject()
            let groupName = producGroup?.fileName()
            let project: PBXFileElement? = projectRef.getObject()
            let fileRefName = project?.fileName()

            return [
                CommentedString(Xcode.ProjectReference.productGroupKey): PlistValue.string(CommentedString(productGroupReference.value, comment: groupName)),
                CommentedString(Xcode.ProjectReference.projectReferenceKey): PlistValue.string(CommentedString(projectRef.value, comment: fileRefName)),
            ]
        })
    }
}
