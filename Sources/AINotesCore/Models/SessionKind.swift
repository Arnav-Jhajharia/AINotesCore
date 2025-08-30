import Foundation

public enum SessionKind: String, Codable, CaseIterable {
    case lecture, tutorial, lab, others
    
    public var displayName: String {
        switch self {
        case .lecture: return "Lecture"
        case .tutorial: return "Tutorial"
        case .lab: return "Lab"
        case .others: return "Others"
        }
    }
    
    public var iconName: String {
        switch self {
        case .lecture: return "person.fill.viewfinder"
        case .tutorial: return "person.2.fill"
        case .lab: return "flask.fill"
        case .others: return "ellipsis.circle.fill"
        }
    }
}