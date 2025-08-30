import Foundation
import CloudKit
import SwiftData

@MainActor
public class CloudKitSetup: ObservableObject {
    public static let shared = CloudKitSetup()
    
    private let container = CKContainer(identifier: "iCloud.com.network.lemma")
    @Published public var isReady = false
    @Published public var error: String?
    
    private init() {}
    
    public func setupCloudKit() async {
        do {
            // Check account status
            let accountStatus = try await container.accountStatus()
            
            guard accountStatus == .available else {
                error = "iCloud account not available: \(accountStatus)"
                return
            }
            
            // Check if we have permission to use CloudKit
            let permission = try await container.requestApplicationPermission(.userDiscoverability)
            
            guard permission == .granted else {
                error = "CloudKit permission not granted"
                return
            }
            
            // Try to fetch the private database
            let database = container.privateCloudDatabase
            let testRecord = CKRecord(recordType: "TestSetup")
            testRecord["testField"] = "test" as CKRecordValue
            
            // Try to save and then delete a test record
            let savedRecord = try await database.save(testRecord)
            try await database.deleteRecord(withID: savedRecord.recordID)
            
            isReady = true
            error = nil
            
            print("✅ CloudKit setup successful!")
            
        } catch {
            self.error = "CloudKit setup failed: \(error.localizedDescription)"
            print("❌ CloudKit setup failed: \(error)")
        }
    }
    
    public func createContainerIfNeeded() async throws {
        // This will attempt to create the necessary record types in CloudKit
        let database = container.privateCloudDatabase
        
        // CloudKit will automatically create the schema when SwiftData tries to sync
        // But we can test the connection here
        
        let query = CKQuery(recordType: "CD_UserSettings", predicate: NSPredicate(value: true))
        let result = try await database.records(matching: query)
        
        print("CloudKit container is accessible. Found \(result.matchResults.count) UserSettings records.")
    }
}