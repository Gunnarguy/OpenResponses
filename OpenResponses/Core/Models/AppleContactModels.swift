//
//  AppleContactModels.swift
//  OpenResponses
//
//  Created by AI Assistant on 11/5/25.
//

import Foundation

/// Summary of a contact for list views
public struct AppleContactSummary: Codable, Sendable {
    public let identifier: String
    public let givenName: String?
    public let familyName: String?
    public let organizationName: String?
    public let phoneNumbers: [String]
    public let emailAddresses: [String]
    
    nonisolated public init(
        identifier: String,
        givenName: String?,
        familyName: String?,
        organizationName: String?,
        phoneNumbers: [String],
        emailAddresses: [String]
    ) {
        self.identifier = identifier
        self.givenName = givenName
        self.familyName = familyName
        self.organizationName = organizationName
        self.phoneNumbers = phoneNumbers
        self.emailAddresses = emailAddresses
    }
    
    public var displayName: String {
        let name = [givenName, familyName]
            .compactMap { $0 }
            .joined(separator: " ")
        
        if name.isEmpty {
            return organizationName ?? "Unknown"
        }
        return name
    }
}

/// Detailed contact information
public struct AppleContactDetail: Codable, Sendable {
    public let identifier: String
    public let givenName: String?
    public let familyName: String?
    public let middleName: String?
    public let namePrefix: String?
    public let nameSuffix: String?
    public let nickname: String?
    public let organizationName: String?
    public let departmentName: String?
    public let jobTitle: String?
    public let phoneNumbers: [ContactPhoneNumber]
    public let emailAddresses: [ContactEmailAddress]
    public let postalAddresses: [ContactPostalAddress]
    public let urlAddresses: [String]
    public let birthdayISO8601: String?
    public let note: String?
    
    nonisolated public init(
        identifier: String,
        givenName: String?,
        familyName: String?,
        middleName: String?,
        namePrefix: String?,
        nameSuffix: String?,
        nickname: String?,
        organizationName: String?,
        departmentName: String?,
        jobTitle: String?,
        phoneNumbers: [ContactPhoneNumber],
        emailAddresses: [ContactEmailAddress],
        postalAddresses: [ContactPostalAddress],
        urlAddresses: [String],
        birthdayISO8601: String?,
        note: String?
    ) {
        self.identifier = identifier
        self.givenName = givenName
        self.familyName = familyName
        self.middleName = middleName
        self.namePrefix = namePrefix
        self.nameSuffix = nameSuffix
        self.nickname = nickname
        self.organizationName = organizationName
        self.departmentName = departmentName
        self.jobTitle = jobTitle
        self.phoneNumbers = phoneNumbers
        self.emailAddresses = emailAddresses
        self.postalAddresses = postalAddresses
        self.urlAddresses = urlAddresses
        self.birthdayISO8601 = birthdayISO8601
        self.note = note
    }
}

public struct ContactPhoneNumber: Codable, Sendable {
    public let label: String?
    public let value: String
    
    nonisolated public init(label: String?, value: String) {
        self.label = label
        self.value = value
    }
}

public struct ContactEmailAddress: Codable, Sendable {
    public let label: String?
    public let value: String
    
    nonisolated public init(label: String?, value: String) {
        self.label = label
        self.value = value
    }
}

public struct ContactPostalAddress: Codable, Sendable {
    public let label: String?
    public let street: String?
    public let city: String?
    public let state: String?
    public let postalCode: String?
    public let country: String?
    
    nonisolated public init(
        label: String?,
        street: String?,
        city: String?,
        state: String?,
        postalCode: String?,
        country: String?
    ) {
        self.label = label
        self.street = street
        self.city = city
        self.state = state
        self.postalCode = postalCode
        self.country = country
    }
}
