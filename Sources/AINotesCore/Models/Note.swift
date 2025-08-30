import Foundation
import SwiftData

@Model
public final class Note {
    public var id: UUID = UUID()
    public var moduleCode: String
    public var sessionStart: Date?  // Optional - allows standalone notes not tied to sessions
    public var title: String
    public var bodyMarkdown: String
    public var pinned: Bool = false
    public var updatedAt: Date
    
    @Relationship
    public var session: ClassSession?
    
    @Relationship
    public var folder: Folder?
    
    @Relationship(deleteRule: .cascade, inverse: \Attachment.note)
    public var attachments: [Attachment] = []
    
    public init(
        moduleCode: String,
        sessionStart: Date? = nil,
        title: String,
        bodyMarkdown: String = ""
    ) {
        self.moduleCode = moduleCode
        self.sessionStart = sessionStart
        self.title = title
        self.bodyMarkdown = bodyMarkdown
        self.updatedAt = Date()
    }
    
    public func update() {
        self.updatedAt = Date()
    }
    
    // Computed property to check if this is a session note
    public var isSessionNote: Bool {
        return session != nil && sessionStart != nil
    }
    
    // Computed property to check if this is a standalone note
    public var isStandaloneNote: Bool {
        return !isSessionNote
    }
    
    public static func createTemplate(for session: ClassSession) -> Note {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: session.start)
        
        let title = "\(session.moduleCode) \(session.kind.displayName) — \(dateString)"
        let template = """
        # \(title)

        ## Key Concepts

        ## Examples

        ## Questions

        ## Action Items
        - [ ] …
        """
        
        return Note(
            moduleCode: session.moduleCode,
            sessionStart: session.start,
            title: title,
            bodyMarkdown: template
        )
    }
    
    // Create a standalone note template
    public static func createStandaloneTemplate(moduleCode: String, title: String? = nil) -> Note {
        let noteTitle = title ?? "Untitled Note"
        let template = """
        # \(noteTitle)

        ## Notes

        - 

        ## Questions

        - 

        ## Action Items

        - [ ] 
        """
        
        return Note(
            moduleCode: moduleCode,
            title: noteTitle,
            bodyMarkdown: template
        )
    }
}