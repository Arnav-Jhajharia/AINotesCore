import Foundation
import UserNotifications
import SwiftData

@MainActor
public class ReminderScheduler {
    private let modelContext: ModelContext
    
    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    public func requestPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }
    
    public func scheduleReminders(leadMinutes: Int = 15) async throws {
        let center = UNUserNotificationCenter.current()
        
        // Cancel existing notifications
        center.removeAllPendingNotificationRequests()
        
        // Get all future sessions
        let now = Date()
        let sessions = try modelContext.fetch(
            FetchDescriptor<ClassSession>(
                predicate: #Predicate { $0.start > now && !$0.cancelled }
            )
        )
        
        for session in sessions {
            let reminderTime = session.start.addingTimeInterval(-TimeInterval(leadMinutes * 60))
            
            if reminderTime > now {
                let content = UNMutableNotificationContent()
                content.title = "\(session.kind.displayName) Starting Soon"
                content.body = "\(session.moduleCode) starts in \(leadMinutes) minutes"
                content.sound = .default
                content.userInfo = [
                    "sessionId": session.compositeId,
                    "moduleCode": session.moduleCode,
                    "sessionStart": session.start.timeIntervalSince1970
                ]
                
                let trigger = UNTimeIntervalNotificationTrigger(
                    timeInterval: reminderTime.timeIntervalSinceNow,
                    repeats: false
                )
                
                let request = UNNotificationRequest(
                    identifier: session.compositeId,
                    content: content,
                    trigger: trigger
                )
                
                try await center.add(request)
            }
        }
    }
}