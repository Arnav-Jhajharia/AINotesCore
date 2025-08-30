import Foundation
import SwiftData

@Model
public final class Folder {
    @Attribute(.unique)
    public var id: UUID = UUID()
    public var name: String
    public var moduleCode: String?  // Optional - allows for custom folders not tied to modules
    public var color: String?       // Hex color for folder customization
    public var isArchived: Bool = false
    public var sortOrder: Int = 0   // For custom ordering
    public var createdAt: Date
    public var updatedAt: Date
    public var sessionType: String? // For session-specific sub-folders (lecture, tutorial, etc.)
    public var isSubFolder: Bool = false // Flag to indicate if this is a sub-folder
    public var parentFolderID: UUID? // ID of parent folder (avoids circular reference)
    
    @Relationship
    public var module: Module?
    
    @Relationship(deleteRule: .cascade, inverse: \Note.folder)
    public var notes: [Note] = []
    
    public init(
        name: String,
        moduleCode: String? = nil,
        color: String? = nil,
        sessionType: String? = nil,
        isSubFolder: Bool = false,
        parentFolderID: UUID? = nil
    ) {
        self.name = name
        self.moduleCode = moduleCode
        self.color = color
        self.sessionType = sessionType
        self.isSubFolder = isSubFolder
        self.parentFolderID = parentFolderID
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    public func update() {
        self.updatedAt = Date()
    }
    
    // Computed property to determine if this is a module folder
    public var isModuleFolder: Bool {
        return moduleCode != nil && module != nil && !isSubFolder
    }
    
    // Get folder icon based on type
    public var iconName: String {
        if isSubFolder {
            // Return session-specific icons for sub-folders
            if let sessionType = sessionType {
                switch sessionType.lowercased() {
                case "lecture": return "person.wave.2"
                case "tutorial": return "person.2.badge.gearshape"
                case "lab", "laboratory": return "flask"
                case "general": return "doc.text"
                default: return "folder"
                }
            }
            return "folder"
        } else if isModuleFolder {
            return "folder.fill"
        } else {
            return "folder"
        }
    }
    
    // Get folder display color
    public var displayColor: String {
        return color ?? "#007AFF" // Default to blue
    }
}