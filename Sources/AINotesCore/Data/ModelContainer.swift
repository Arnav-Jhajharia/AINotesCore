import Foundation
import SwiftData

public extension ModelContainer {
    static func createAINotesContainer() throws -> ModelContainer {
        let schema = Schema([
            UserSettings.self,
            Module.self,
            ClassSession.self,
            Note.self,
            Attachment.self,
            Folder.self
        ])
        
        // Use local storage only (CloudKit requires Apple Developer account)
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )
        
        return try ModelContainer(for: schema, configurations: [modelConfiguration])
    }
    
    // Method to enable CloudKit later when developer account is available
    static func createCloudKitContainer() throws -> ModelContainer {
        let schema = Schema([
            UserSettings.self,
            Module.self,
            ClassSession.self,
            Note.self,
            Attachment.self,
            Folder.self
        ])
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .private("iCloud.com.network.lemma")
        )
        
        return try ModelContainer(for: schema, configurations: [modelConfiguration])
    }
}