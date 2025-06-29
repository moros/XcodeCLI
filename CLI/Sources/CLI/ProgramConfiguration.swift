import Foundation
import PListKit

public struct ProgramConfiguration {
    public let project: String?
    public let workspace: String?
    
    public init(project: String? = nil, workspace: String? = nil) {
        self.project = project
        self.workspace = workspace
    }
    
    // MARK: - Plist Serialization
    
    public func toPlist() -> DictionaryPList {
        var plist: PListDictionary = [:]
        if let project = project {
            plist["Project"] = project
        }
        if let workspace = workspace {
            plist["Workspace"] = workspace
        }
        return DictionaryPList(root: plist)
    }
    
    public static func fromPlist(_ plist: DictionaryPList) throws -> ProgramConfiguration {
        let project = plist.storage[string: "Project"]
        let workspace = plist.storage[string: "Workspace"]
        return ProgramConfiguration(project: project, workspace: workspace)
    }
} 
