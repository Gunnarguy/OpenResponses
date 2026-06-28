import Foundation

struct ResponseSettingDescriptor: Identifiable {
    enum Group: String, CaseIterable {
        case model = "Model & Generation"
        case instructions = "Instructions"
        case tools = "Tools"
        case toolAdvanced = "Advanced Tool Settings"
        case output = "Output Formatting"
        case reasoning = "Reasoning"
        case state = "State & Context"
        case streaming = "Streaming"
        case safety = "Safety & Moderation"
        case cache = "Caching"
        case debug = "Debug & Telemetry"
        case legacy = "Legacy"
        case hidden = "Hidden"
    }

    enum Exposure: Equatable {
        case primary
        case advanced
        case debug
        case legacy
        case intentionallyHidden(reason: String)
    }

    let id: String
    let promptKeyPathName: String
    let apiField: String?
    let group: Group
    let exposure: Exposure
    let title: String
    let description: String
    let defaultValueDescription: String
    let validValues: [String]?
    let minValue: Double?
    let maxValue: Double?
    let requiresModelCapability: String?
    let requiresTool: String? // Simplified to String for now
    let docsAnchor: String?

    init(
        id: String? = nil,
        promptKeyPathName: String,
        apiField: String? = nil,
        group: Group,
        exposure: Exposure,
        title: String,
        description: String,
        defaultValueDescription: String,
        validValues: [String]? = nil,
        minValue: Double? = nil,
        maxValue: Double? = nil,
        requiresModelCapability: String? = nil,
        requiresTool: String? = nil,
        docsAnchor: String? = nil
    ) {
        self.id = id ?? promptKeyPathName
        self.promptKeyPathName = promptKeyPathName
        self.apiField = apiField
        self.group = group
        self.exposure = exposure
        self.title = title
        self.description = description
        self.defaultValueDescription = defaultValueDescription
        self.validValues = validValues
        self.minValue = minValue
        self.maxValue = maxValue
        self.requiresModelCapability = requiresModelCapability
        self.requiresTool = requiresTool
        self.docsAnchor = docsAnchor
    }
}
