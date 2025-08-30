import Foundation
import SwiftData
import NUSModsClient

@MainActor
public class SessionGenerator {
    private let modelContext: ModelContext
    private let nusClient: NUSModsClient
    private let calendar: AcademicCalendar
    
    public init(modelContext: ModelContext, nusClient: NUSModsClient, calendar: AcademicCalendar) {
        self.modelContext = modelContext
        self.nusClient = nusClient
        self.calendar = calendar
    }
    
    public func generateSessions(for module: Module, semester: NUSModsClient.Semester) async throws {
        let lessons = try await nusClient.fetchTimetable(moduleCode: module.code, semester: semester)
        let datedSessions = nusClient.expandLessonsToSessions(
            moduleCode: module.code,
            semester: semester,
            lessons: lessons,
            calendar: calendar
        )
        
        // Convert to ClassSession and save
        for datedSession in datedSessions {
            let sessionKind = SessionKind.from(datedSession.kind) ?? .others
            let session = ClassSession(
                moduleCode: datedSession.moduleCode,
                start: datedSession.start,
                end: datedSession.end,
                kind: sessionKind,
                location: datedSession.location
            )
            session.module = module
            modelContext.insert(session)
            
            // Create a note for each session
            let note = Note.createTemplate(for: session)
            note.session = session
            modelContext.insert(note)
        }
        
        try modelContext.save()
    }
    
    public func regenerateAllSessions() async throws {
        let modules = try modelContext.fetch(FetchDescriptor<Module>())
        
        for module in modules {
            // Clear existing sessions
            for session in module.sessions {
                modelContext.delete(session)
            }
            
            // Determine semester from semesterKey
            let semester: NUSModsClient.Semester = module.semesterKey.contains("S1") ? .sem1 : .sem2
            
            try await generateSessions(for: module, semester: semester)
        }
    }
}

// Add this extension to convert string to SessionKind
extension SessionKind {
    static func from(_ raw: String) -> SessionKind? {
        let s = raw.lowercased()
        if s.contains("lec") { return .lecture }
        else if s.contains("tut") { return .tutorial }
        else if s.contains("lab") { return .lab }
        else { return .others }
    }
}