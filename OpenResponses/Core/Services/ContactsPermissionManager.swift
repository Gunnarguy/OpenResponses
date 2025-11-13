//
//  ContactsPermissionManager.swift
//  OpenResponses
//
//  Created by AI Assistant on 11/5/25.
//

import Foundation
import Contacts

/// Manages access and permissions for Apple Contacts.
/// Thread-safe singleton that handles CNContactStore authorization.
public final class ContactsPermissionManager: Sendable {
    
    public static let shared = ContactsPermissionManager()
    
    private let store: CNContactStore
    
    private init() {
        self.store = CNContactStore()
    }
    
    /// Request full access to Contacts
    @MainActor
    public func requestAccess() async throws {
        let status = CNContactStore.authorizationStatus(for: .contacts)
        
        switch status {
        case .authorized:
            return
        case .notDetermined:
            let granted = try await store.requestAccess(for: .contacts)
            if !granted {
                throw ContactsAccessError.permissionDenied
            }
        case .denied, .restricted:
            throw ContactsAccessError.permissionDenied
        default:
            // Handle .limited for iOS 18+ and @unknown cases
            if #available(iOS 18.0, *) {
                if status == .limited {
                    return
                }
            }
            throw ContactsAccessError.unknownAuthorizationStatus
        }
    }
    
    /// Check current authorization status
    public func authorizationStatus() -> CNAuthorizationStatus {
        CNContactStore.authorizationStatus(for: .contacts)
    }
    
    /// Ensure access is granted before performing operations
    @MainActor
    public func ensureAccess() async throws {
        let status = authorizationStatus()
        
        // Check if we have adequate access
        var hasAccess = status == .authorized
        
        if #available(iOS 18.0, *) {
            hasAccess = hasAccess || status == .limited
        }
        
        if !hasAccess {
            try await requestAccess()
        }
    }
    
    /// Get the CNContactStore instance
    public func getStore() -> CNContactStore {
        store
    }
}

/// Errors related to Contacts access
public enum ContactsAccessError: LocalizedError {
    case permissionDenied
    case unknownAuthorizationStatus
    case operationUnavailable(String)
    
    public var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Contacts permission denied. Please enable in Settings."
        case .unknownAuthorizationStatus:
            return "Unknown Contacts authorization status."
        case .operationUnavailable(let message):
            return "Contacts operation unavailable: \(message)"
        }
    }
}
