import Foundation
import SwiftData

@Model
public final class UserSettings {
    @Attribute(.unique)
    public var id: String = "singleton"
    public var academicYear: String?
    public var semester: String?
    public var studentName: String?
    public var studentID: String?
    public var reminderLeadMinutes: Int = 15
    public var createdAt: Date
    public var updatedAt: Date
    
    public init(
        academicYear: String? = nil,
        semester: String? = nil,
        studentName: String? = nil,
        studentID: String? = nil,
        reminderLeadMinutes: Int = 15
    ) {
        self.academicYear = academicYear
        self.semester = semester
        self.studentName = studentName
        self.studentID = studentID
        self.reminderLeadMinutes = reminderLeadMinutes
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    public func update() {
        self.updatedAt = Date()
    }
}