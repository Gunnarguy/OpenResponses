//
//  ContactsRepository.swift
//  OpenResponses
//
//  Created by AI Assistant on 11/5/25.
//

import Foundation
import Contacts

/// Repository for Apple Contacts operations
public final class ContactsRepository: Sendable {
    
    private let permissionManager: ContactsPermissionManager
    private let isoFormatter: ISO8601DateFormatter
    
    public init(permissionManager: ContactsPermissionManager = .shared) {
        self.permissionManager = permissionManager
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        self.isoFormatter = formatter
    }
    
    /// Search contacts by name, email, or phone
    public func searchContacts(query: String, limit: Int = 50) async throws -> [AppleContactSummary] {
        try await permissionManager.ensureAccess()
        let store = permissionManager.getStore()
        
        // Run search on background thread
        return try await Task.detached {
            let keysToFetch: [CNKeyDescriptor] = [
                CNContactIdentifierKey as CNKeyDescriptor,
                CNContactGivenNameKey as CNKeyDescriptor,
                CNContactFamilyNameKey as CNKeyDescriptor,
                CNContactOrganizationNameKey as CNKeyDescriptor,
                CNContactPhoneNumbersKey as CNKeyDescriptor,
                CNContactEmailAddressesKey as CNKeyDescriptor
            ]
            
            var results: [CNContact] = []
            
            // Search by name
            let predicate = CNContact.predicateForContacts(matchingName: query)
            let contacts = try store.unifiedContacts(matching: predicate, keysToFetch: keysToFetch)
            results.append(contentsOf: contacts)
            
            // Limit results
            let limited = Array(results.prefix(limit))
            
            return limited.map { contact in
                AppleContactSummary(
                    identifier: contact.identifier,
                    givenName: contact.givenName.isEmpty ? nil : contact.givenName,
                    familyName: contact.familyName.isEmpty ? nil : contact.familyName,
                    organizationName: contact.organizationName.isEmpty ? nil : contact.organizationName,
                    phoneNumbers: contact.phoneNumbers.map { $0.value.stringValue },
                    emailAddresses: contact.emailAddresses.map { $0.value as String }
                )
            }
        }.value
    }
    
    /// Get all contacts (useful for "list all" queries)
    public func getAllContacts(limit: Int = 100) async throws -> [AppleContactSummary] {
        try await permissionManager.ensureAccess()
        let store = permissionManager.getStore()
        
        // Run enumeration on background thread
        return try await Task.detached {
            let keysToFetch: [CNKeyDescriptor] = [
                CNContactIdentifierKey as CNKeyDescriptor,
                CNContactGivenNameKey as CNKeyDescriptor,
                CNContactFamilyNameKey as CNKeyDescriptor,
                CNContactOrganizationNameKey as CNKeyDescriptor,
                CNContactPhoneNumbersKey as CNKeyDescriptor,
                CNContactEmailAddressesKey as CNKeyDescriptor
            ]
            
            var results: [CNContact] = []
            let request = CNContactFetchRequest(keysToFetch: keysToFetch)
            
            try store.enumerateContacts(with: request) { contact, stop in
                results.append(contact)
                if results.count >= limit {
                    stop.pointee = true
                }
            }
            
            return results.map { contact in
                AppleContactSummary(
                    identifier: contact.identifier,
                    givenName: contact.givenName.isEmpty ? nil : contact.givenName,
                    familyName: contact.familyName.isEmpty ? nil : contact.familyName,
                    organizationName: contact.organizationName.isEmpty ? nil : contact.organizationName,
                    phoneNumbers: contact.phoneNumbers.map { $0.value.stringValue },
                    emailAddresses: contact.emailAddresses.map { $0.value as String }
                )
            }
        }.value
    }
    
    /// Get detailed contact by identifier
    public func getContact(identifier: String) async throws -> AppleContactDetail {
        try await permissionManager.ensureAccess()
        let store = permissionManager.getStore()
        
        // Run fetch on background thread
        return try await Task.detached { [isoFormatter] in
            let keysToFetch: [CNKeyDescriptor] = [
                CNContactIdentifierKey as CNKeyDescriptor,
                CNContactGivenNameKey as CNKeyDescriptor,
                CNContactFamilyNameKey as CNKeyDescriptor,
                CNContactMiddleNameKey as CNKeyDescriptor,
                CNContactNamePrefixKey as CNKeyDescriptor,
                CNContactNameSuffixKey as CNKeyDescriptor,
                CNContactNicknameKey as CNKeyDescriptor,
                CNContactOrganizationNameKey as CNKeyDescriptor,
                CNContactDepartmentNameKey as CNKeyDescriptor,
                CNContactJobTitleKey as CNKeyDescriptor,
                CNContactPhoneNumbersKey as CNKeyDescriptor,
                CNContactEmailAddressesKey as CNKeyDescriptor,
                CNContactPostalAddressesKey as CNKeyDescriptor,
                CNContactUrlAddressesKey as CNKeyDescriptor,
                CNContactBirthdayKey as CNKeyDescriptor,
                CNContactNoteKey as CNKeyDescriptor
            ]
            
            let contact = try store.unifiedContact(withIdentifier: identifier, keysToFetch: keysToFetch)
        
        let phoneNumbers = contact.phoneNumbers.map { phone in
            ContactPhoneNumber(
                label: phone.label.flatMap { CNLabeledValue<NSString>.localizedString(forLabel: $0) },
                value: phone.value.stringValue
            )
        }
        
        let emailAddresses = contact.emailAddresses.map { email in
            ContactEmailAddress(
                label: email.label.flatMap { CNLabeledValue<NSString>.localizedString(forLabel: $0) },
                value: email.value as String
            )
        }
        
        let postalAddresses = contact.postalAddresses.map { address in
            let postal = address.value
            return ContactPostalAddress(
                label: address.label.flatMap { CNLabeledValue<CNPostalAddress>.localizedString(forLabel: $0) },
                street: postal.street.isEmpty ? nil : postal.street,
                city: postal.city.isEmpty ? nil : postal.city,
                state: postal.state.isEmpty ? nil : postal.state,
                postalCode: postal.postalCode.isEmpty ? nil : postal.postalCode,
                country: postal.country.isEmpty ? nil : postal.country
            )
        }
        
        let urlAddresses = contact.urlAddresses.map { $0.value as String }
        
        let birthdayISO: String?
        if let birthday = contact.birthday,
           let date = Calendar.current.date(from: birthday) {
            birthdayISO = isoFormatter.string(from: date)
        } else {
            birthdayISO = nil
        }
        
        return AppleContactDetail(
            identifier: contact.identifier,
            givenName: contact.givenName.isEmpty ? nil : contact.givenName,
            familyName: contact.familyName.isEmpty ? nil : contact.familyName,
            middleName: contact.middleName.isEmpty ? nil : contact.middleName,
            namePrefix: contact.namePrefix.isEmpty ? nil : contact.namePrefix,
            nameSuffix: contact.nameSuffix.isEmpty ? nil : contact.nameSuffix,
            nickname: contact.nickname.isEmpty ? nil : contact.nickname,
            organizationName: contact.organizationName.isEmpty ? nil : contact.organizationName,
            departmentName: contact.departmentName.isEmpty ? nil : contact.departmentName,
            jobTitle: contact.jobTitle.isEmpty ? nil : contact.jobTitle,
            phoneNumbers: phoneNumbers,
            emailAddresses: emailAddresses,
            postalAddresses: postalAddresses,
            urlAddresses: urlAddresses,
            birthdayISO8601: birthdayISO,
            note: contact.note.isEmpty ? nil : contact.note
        )
        }.value
    }
    
    /// Create a new contact
    public func createContact(
        givenName: String?,
        familyName: String?,
        organizationName: String?,
        phoneNumber: String?,
        phoneLabel: String?,
        emailAddress: String?,
        emailLabel: String?,
        note: String?
    ) async throws -> AppleContactDetail {
        try await permissionManager.ensureAccess()
        let store = permissionManager.getStore()
        
        // Create contact on background thread
        let identifier = try await Task.detached {
            let contact = CNMutableContact()
            
            if let givenName {
                contact.givenName = givenName
            }
            if let familyName {
                contact.familyName = familyName
            }
            if let organizationName {
                contact.organizationName = organizationName
            }
            if let note {
                contact.note = note
            }
            
            // Add phone number
            if let phoneNumber {
                let phone = CNLabeledValue(
                    label: phoneLabel ?? CNLabelPhoneNumberMain,
                    value: CNPhoneNumber(stringValue: phoneNumber)
                )
                contact.phoneNumbers = [phone]
            }
            
            // Add email address
            if let emailAddress {
                let email = CNLabeledValue(
                    label: emailLabel ?? CNLabelHome,
                    value: emailAddress as NSString
                )
                contact.emailAddresses = [email]
            }
            
            let saveRequest = CNSaveRequest()
            saveRequest.add(contact, toContainerWithIdentifier: nil)
            try store.execute(saveRequest)
            
            return contact.identifier
        }.value
        
        // Fetch the created contact
        return try await getContact(identifier: identifier)
    }
}
