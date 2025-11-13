import Foundation

#if canImport(EventKit)
import EventKit

/// Centralized manager for EventKit permissions with iOS 17+ support.
/// Thread-safe singleton for managing EventKit permissions.
public final class EventKitPermissionManager: Sendable {
    public static let shared = EventKitPermissionManager()
    public let store = EKEventStore()
    
    private init() {}

    /// Ensures access is granted, requesting if necessary.
    public func ensureAccess(for entityType: EKEntityType) async throws {
        switch EKEventStore.authorizationStatus(for: entityType) {
        case .notDetermined:
            try await requestAccess(for: entityType)
        case .denied:
            throw AppleDataAccessError.accessDenied(entity: Self.label(for: entityType))
        case .restricted:
            throw AppleDataAccessError.accessRestricted(entity: Self.label(for: entityType))
        case .authorized, .fullAccess:
            return
        case .writeOnly:
            throw AppleDataAccessError.writeOnlyAccess(entity: Self.label(for: entityType))
        @unknown default:
            throw AppleDataAccessError.operationUnavailable("Unknown authorization status for \(Self.label(for: entityType)).")
        }
    }

    /// Requests permission for the provided entity type.
    private func requestAccess(for entityType: EKEntityType) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let completionHandler: @Sendable (Bool, Error?) -> Void = { granted, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                if granted {
                    continuation.resume(returning: ())
                } else {
                    continuation.resume(throwing: AppleDataAccessError.accessDenied(entity: Self.label(for: entityType)))
                }
            }
            
            if #available(iOS 17.0, macOS 14.0, *) {
                switch entityType {
                case .event:
                    store.requestFullAccessToEvents(completion: completionHandler)
                case .reminder:
                    store.requestFullAccessToReminders(completion: completionHandler)
                @unknown default:
                    continuation.resume(throwing: AppleDataAccessError.operationUnavailable("Unsupported entity type."))
                }
            } else {
                store.requestAccess(to: entityType, completion: completionHandler)
            }
        }
    }

    /// Gets the current authorization status for an entity type.
    public func authorizationStatus(for entityType: EKEntityType) -> EKAuthorizationStatus {
        return EKEventStore.authorizationStatus(for: entityType)
    }

    /// Convenience helper for consistent human-readable labels.
    nonisolated private static func label(for entityType: EKEntityType) -> String {
        switch entityType {
        case .event: return "Calendar"
        case .reminder: return "Reminders"
        @unknown default: return "data"
        }
    }
}
#endif
