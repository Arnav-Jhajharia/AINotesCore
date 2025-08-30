import Foundation
import SwiftUI

@MainActor
@Observable
public class SyncStatusService {
    public enum SyncStatus {
        case localOnly
        case needsDeveloperAccount
        case cloudKitReady
    }
    
    public var syncStatus: SyncStatus = .needsDeveloperAccount
    public var isCloudKitAvailable = false
    
    public init() {
        // Local storage mode - CloudKit requires Apple Developer account
        checkLocalStatus()
    }
    
    public func checkCloudKitStatus() async {
        checkLocalStatus()
    }
    
    private func checkLocalStatus() {
        syncStatus = .needsDeveloperAccount
        isCloudKitAvailable = false
    }
    
    public var statusDescription: String {
        switch syncStatus {
        case .localOnly:
            return "Local storage only"
        case .needsDeveloperAccount:
            return "CloudKit requires Apple Developer account"
        case .cloudKitReady:
            return "Synced with iCloud"
        }
    }
    
    public var statusColor: Color {
        switch syncStatus {
        case .localOnly:
            return .blue
        case .needsDeveloperAccount:
            return .orange
        case .cloudKitReady:
            return .green
        }
    }
}