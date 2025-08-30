import Foundation
import SwiftData

@Model
public final class ClassSession {
    public var moduleCode: String
    public var start: Date
    public var end: Date
    public var kindRaw: String
    public var location: String?
    public var weekNumber: Int?
    public var cancelled: Bool = false
    public var createdAt: Date
    public var updatedAt: Date
    
    @Relationship
    public var module: Module?
    
    @Relationship(deleteRule: .cascade, inverse: \Note.session)
    public var notes: [Note] = []
    
    public var kind: SessionKind {
        get { SessionKind(rawValue: kindRaw) ?? .others }
        set { kindRaw = newValue.rawValue }
    }
    
    public init(
        moduleCode: String,
        start: Date,
        end: Date,
        kind: SessionKind,
        location: String? = nil,
        weekNumber: Int? = nil
    ) {
        self.moduleCode = moduleCode
        self.start = start
        self.end = end
        self.kindRaw = kind.rawValue
        self.location = location
        self.weekNumber = weekNumber
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    public func update() {
        self.updatedAt = Date()
    }
    
    public var compositeId: String {
        "\(moduleCode)-\(start.timeIntervalSince1970)-\(kindRaw)"
    }
}