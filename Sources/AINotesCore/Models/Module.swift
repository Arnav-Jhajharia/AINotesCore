import Foundation
import SwiftData

@Model
public final class Module {
    @Attribute(.unique)
    public var code: String
    public var title: String
    public var semesterKey: String
    public var tutorialGroup: String?
    public var createdAt: Date
    public var updatedAt: Date
    
    @Relationship(deleteRule: .cascade, inverse: \ClassSession.module)
    public var sessions: [ClassSession] = []
    
    @Relationship(deleteRule: .cascade, inverse: \Folder.module)
    public var folder: Folder?
    
    public init(
        code: String,
        title: String,
        semesterKey: String,
        tutorialGroup: String? = nil
    ) {
        self.code = code
        self.title = title
        self.semesterKey = semesterKey
        self.tutorialGroup = tutorialGroup
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    public func update() {
        self.updatedAt = Date()
    }
    
    // Create the folder for this module if it doesn't exist
    public func ensureFolder() -> Folder {
        if let existingFolder = folder {
            return existingFolder
        }
        
        let newFolder = Folder(
            name: "\(code) - \(title)",
            moduleCode: code,
            color: moduleColor()
        )
        newFolder.module = self
        self.folder = newFolder
        
        return newFolder
    }
    
    // Generate a color based on module code for visual distinction
    private func moduleColor() -> String {
        let colors = ["#007AFF", "#FF3B30", "#FF9500", "#FFCC00", "#34C759", "#5856D6", "#AF52DE", "#FF2D92"]
        let hash = abs(code.hashValue)
        let colorIndex = hash % colors.count
        return colors[colorIndex]
    }
}