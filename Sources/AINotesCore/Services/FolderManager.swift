import Foundation
import SwiftData

public class FolderManager {
    private let modelContext: ModelContext
    
    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // Ensure a module has a main folder with sub-folders for session types
    public func ensureFolderForModule(_ module: Module) -> Folder {
        // Check if main module folder already exists
        if let existingFolder = module.folder {
            // Ensure sub-folders exist
            ensureSubFoldersForModule(module, parentFolder: existingFolder)
            return existingFolder
        }
        
        // Create main module folder
        let mainFolder = Folder(
            name: "\(module.code) - \(module.title)",
            moduleCode: module.code,
            color: moduleColor(for: module.code),
            isSubFolder: false
        )
        mainFolder.module = module
        module.folder = mainFolder
        modelContext.insert(mainFolder)
        
        // Create sub-folders for session types and general notes
        ensureSubFoldersForModule(module, parentFolder: mainFolder)
        
        do {
            try modelContext.save()
            return mainFolder
        } catch {
            print("Failed to create folder structure for module \(module.code): \(error)")
            return mainFolder
        }
    }
    
    // Create sub-folders for each session type within the main module folder
    private func ensureSubFoldersForModule(_ module: Module, parentFolder: Folder) {
        let sessionTypes = Set(module.sessions.map { $0.kind.rawValue })
        
        // Always create a "General" sub-folder for standalone notes
        var requiredSubFolders = sessionTypes
        requiredSubFolders.insert("general")
        
        // Get existing sub-folders for this module
        let existingSubFolders = getSubFolders(for: parentFolder)
        
        for sessionType in requiredSubFolders {
            let subFolderName = sessionType == "general" ? "General" : sessionType.capitalized
            
            // Check if sub-folder already exists
            if !existingSubFolders.contains(where: { $0.name == subFolderName && $0.sessionType == sessionType }) {
                let subFolder = Folder(
                    name: subFolderName,
                    moduleCode: module.code,
                    color: sessionTypeColor(sessionType),
                    sessionType: sessionType,
                    isSubFolder: true,
                    parentFolderID: parentFolder.id
                )
                subFolder.module = module
                modelContext.insert(subFolder)
            }
        }
    }
    
    // Get sub-folders for a parent folder
    public func getSubFolders(for parentFolder: Folder) -> [Folder] {
        let fetchDescriptor = FetchDescriptor<Folder>()
        
        do {
            let allFolders = try modelContext.fetch(fetchDescriptor)
            return allFolders.filter { $0.parentFolderID == parentFolder.id }
        } catch {
            print("Failed to fetch sub-folders: \(error)")
            return []
        }
    }
    
    // Get all notes for a module (from main folder and all sub-folders)
    public func getAllNotesForModule(_ module: Module) -> [Note] {
        guard let mainFolder = module.folder else { return [] }
        
        var allNotes = mainFolder.notes
        let subFolders = getSubFolders(for: mainFolder)
        
        for subFolder in subFolders {
            allNotes.append(contentsOf: subFolder.notes)
        }
        
        return allNotes.sorted { $0.updatedAt > $1.updatedAt }
    }
    
    // Get the appropriate sub-folder for a note based on session type
    private func getSubFolderForNote(module: Module, sessionType: String?) -> Folder? {
        guard let mainFolder = module.folder else { return nil }
        
        let targetSessionType = sessionType ?? "general"
        let subFolderName = targetSessionType == "general" ? "General" : targetSessionType.capitalized
        
        let subFolders = getSubFolders(for: mainFolder)
        return subFolders.first { $0.name == subFolderName }
    }
    
    // Create a note in the appropriate sub-folder based on session type
    public func createNoteInModuleFolder(
        module: Module, 
        session: ClassSession? = nil,
        title: String? = nil,
        isSessionNote: Bool = false
    ) -> Note {
        let mainFolder = ensureFolderForModule(module)
        
        // Determine which sub-folder to use
        let sessionType = session?.kind.rawValue ?? "general"
        let targetFolder = getSubFolderForNote(module: module, sessionType: sessionType) ?? mainFolder
        
        let note: Note
        if isSessionNote, let session = session {
            note = Note.createTemplate(for: session)
            note.session = session
        } else {
            note = Note.createStandaloneTemplate(
                moduleCode: module.code,
                title: title
            )
        }
        
        note.folder = targetFolder
        targetFolder.notes.append(note)
        modelContext.insert(note)
        
        return note
    }
    
    // Get all notes for a module (alias for backward compatibility)
    public func getNotesForModule(_ module: Module) -> [Note] {
        return getAllNotesForModule(module)
    }
    
    // Get notes for a specific session type
    public func getNotesForSessionType(_ sessionType: SessionKind, in module: Module) -> [Note] {
        let subFolder = getSubFolderForNote(module: module, sessionType: sessionType.rawValue)
        return subFolder?.notes.sorted { $0.updatedAt > $1.updatedAt } ?? []
    }
    
    // Create a quick note for a module (goes into General sub-folder)
    public func createQuickNote(for module: Module) -> Note {
        return createNoteInModuleFolder(
            module: module,
            title: "Quick Note - \(Date().formatted(date: .abbreviated, time: .shortened))"
        )
    }
    
    // Generate color for module based on code
    private func moduleColor(for moduleCode: String) -> String {
        let colors = ["#007AFF", "#FF3B30", "#FF9500", "#FFCC00", "#34C759", "#5856D6", "#AF52DE", "#FF2D92"]
        let hash = abs(moduleCode.hashValue)
        let colorIndex = hash % colors.count
        return colors[colorIndex]
    }
    
    // Get color for session type
    private func sessionTypeColor(_ sessionType: String) -> String {
        switch sessionType.lowercased() {
        case "lecture": return "#007AFF"  // Blue
        case "tutorial": return "#34C759" // Green
        case "lab", "laboratory": return "#FF9500" // Orange
        case "general": return "#6366F1"  // Indigo
        default: return "#AF52DE"         // Purple
        }
    }
    
    // Clean up duplicate folders created outside module structure
    private func cleanupDuplicateFolders() {
        let fetchDescriptor = FetchDescriptor<Folder>()
        
        do {
            let allFolders = try modelContext.fetch(fetchDescriptor)
            
            // Find standalone folders that should be sub-folders or are duplicates
            var foldersToDelete: [Folder] = []
            
            for folder in allFolders {
                // Check for standalone session-type folders that should be sub-folders
                if !folder.isSubFolder && 
                   folder.moduleCode == nil && 
                   (folder.name == "General" || folder.name == "Others" || folder.name == "Lecture" || folder.name == "Tutorial" || folder.name == "Lab") {
                    
                    // This is a standalone session-type folder that shouldn't exist
                    foldersToDelete.append(folder)
                }
                
                // Check for module folders that were created incorrectly
                if let moduleCode = folder.moduleCode,
                   !folder.isSubFolder,
                   !folder.isModuleFolder,
                   folder.name.contains(" - ") && !folder.name.hasPrefix(moduleCode + " - ") {
                    
                    // This looks like a session-type folder created at module level
                    foldersToDelete.append(folder)
                }
            }
            
            // Move notes from folders to be deleted to appropriate locations
            for folderToDelete in foldersToDelete {
                for note in folderToDelete.notes {
                    // Try to find the appropriate module folder for this note
                    if let module = allFolders.first(where: { 
                        $0.moduleCode == note.moduleCode && $0.isModuleFolder 
                    })?.module {
                        
                        // Find or create the appropriate sub-folder
                        let sessionType = note.session?.kind.rawValue ?? "general"
                        if let targetFolder = getSubFolderForNote(module: module, sessionType: sessionType) {
                            note.folder = targetFolder
                            targetFolder.notes.append(note)
                        } else {
                            // Fallback to main module folder
                            let mainFolder = ensureFolderForModule(module)
                            note.folder = mainFolder
                            mainFolder.notes.append(note)
                        }
                    } else {
                        // If no module found, create a proper custom folder or move to Quick Notes
                        let quickNotesFolder = findOrCreateQuickNotesFolder()
                        note.folder = quickNotesFolder
                        quickNotesFolder.notes.append(note)
                    }
                }
                
                modelContext.delete(folderToDelete)
            }
            
            try modelContext.save()
        } catch {
            print("Failed to cleanup duplicate folders: \(error)")
        }
    }
    
    // Find or create the Quick Notes folder
    private func findOrCreateQuickNotesFolder() -> Folder {
        let fetchDescriptor = FetchDescriptor<Folder>()
        
        do {
            let allFolders = try modelContext.fetch(fetchDescriptor)
            
            if let quickNotesFolder = allFolders.first(where: { 
                $0.name == "Quick Notes" && !$0.isModuleFolder && !$0.isSubFolder 
            }) {
                return quickNotesFolder
            } else {
                // Create Quick Notes folder
                let quickNotesFolder = Folder(
                    name: "Quick Notes", 
                    color: "#007AFF"
                )
                modelContext.insert(quickNotesFolder)
                return quickNotesFolder
            }
        } catch {
            print("Failed to find/create Quick Notes folder: \(error)")
            // Fallback - create new folder
            let quickNotesFolder = Folder(name: "Quick Notes", color: "#007AFF")
            modelContext.insert(quickNotesFolder)
            return quickNotesFolder
        }
    }
    
    // Enhanced migration with better cleanup
    public func migrateExistingNotesToFolders() {
        let fetchDescriptor = FetchDescriptor<Note>()
        
        do {
            let notes = try modelContext.fetch(fetchDescriptor)
            let moduleFetchDescriptor = FetchDescriptor<Module>()
            let modules = try modelContext.fetch(moduleFetchDescriptor)
            
            for note in notes where note.folder == nil {
                if let module = modules.first(where: { $0.code == note.moduleCode }) {
                    // Determine session type for proper sub-folder placement
                    let sessionType = note.session?.kind.rawValue ?? "general"
                    let targetFolder = getSubFolderForNote(module: module, sessionType: sessionType)
                        ?? ensureFolderForModule(module)
                    
                    note.folder = targetFolder
                    targetFolder.notes.append(note)
                }
            }
            
            // Clean up any orphaned or duplicate folders
            cleanupDuplicateFolders()
            
            try modelContext.save()
        } catch {
            print("Failed to migrate notes to folders: \(error)")
        }
    }
    
    // Add a method to completely reset and rebuild folder structure
    public func rebuildFolderStructure() {
        let folderDescriptor = FetchDescriptor<Folder>()
        let moduleDescriptor = FetchDescriptor<Module>()
        let noteDescriptor = FetchDescriptor<Note>()
        
        do {
            let allFolders = try modelContext.fetch(folderDescriptor)
            let allModules = try modelContext.fetch(moduleDescriptor)
            let allNotes = try modelContext.fetch(noteDescriptor)
            
            // Delete all existing folders
            for folder in allFolders {
                modelContext.delete(folder)
            }
            
            // Clear folder relationships from modules and notes
            for module in allModules {
                module.folder = nil
            }
            
            for note in allNotes {
                note.folder = nil
            }
            
            try modelContext.save()
            
            // Rebuild folder structure from scratch
            for module in allModules {
                let mainFolder = ensureFolderForModule(module)
                
                // Move notes to appropriate sub-folders
                let moduleNotes = allNotes.filter { $0.moduleCode == module.code }
                for note in moduleNotes {
                    let sessionType = note.session?.kind.rawValue ?? "general"
                    let targetFolder = getSubFolderForNote(module: module, sessionType: sessionType) ?? mainFolder
                    note.folder = targetFolder
                    targetFolder.notes.append(note)
                }
            }
            
            // Handle notes without modules (create Quick Notes folder)
            let orphanNotes = allNotes.filter { note in
                !allModules.contains { $0.code == note.moduleCode }
            }
            
            if !orphanNotes.isEmpty {
                let quickNotesFolder = findOrCreateQuickNotesFolder()
                for note in orphanNotes {
                    note.folder = quickNotesFolder
                    quickNotesFolder.notes.append(note)
                }
            }
            
            try modelContext.save()
            
        } catch {
            print("Failed to rebuild folder structure: \(error)")
        }
    }
}