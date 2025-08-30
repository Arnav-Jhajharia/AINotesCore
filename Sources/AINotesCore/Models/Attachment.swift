import Foundation
import SwiftData

@Model
public final class Attachment {
    public var noteID: UUID
    public var filename: String
    public var bytes: Data?
    public var fileSize: Int?
    public var mimeType: String?
    public var createdAt: Date
    
    @Relationship
    public var note: Note?
    
    public init(
        noteID: UUID,
        filename: String,
        bytes: Data? = nil,
        fileSize: Int? = nil,
        mimeType: String? = nil
    ) {
        self.noteID = noteID
        self.filename = filename
        self.bytes = bytes
        self.fileSize = fileSize
        self.mimeType = mimeType
        self.createdAt = Date()
    }
}