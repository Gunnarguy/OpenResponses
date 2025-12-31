import Foundation

#if canImport(EventKit)
import EventKit
#endif

/// A container for managing dependencies across the application.
@MainActor
class AppContainer {
    /// The shared singleton instance of the app container.
    static let shared = AppContainer()

    /// The service responsible for handling OpenAI API communications.
    /// It conforms to `OpenAIServiceProtocol` for better testability and modularity.
    let openAIService: OpenAIServiceProtocol
    
    /// The service for on-device computer use automation.
    let computerService: ComputerService
    
    #if canImport(EventKit)
    /// Permission manager for Apple Calendar and Reminders access.
    let eventKitPermissionManager: EventKitPermissionManager
    
    /// Repository for Apple Calendar operations.
    let appleCalendarRepository: AppleCalendarRepository
    
    /// Repository for Apple Reminders operations.
    let appleReminderRepository: AppleReminderRepository
    
    /// Tool provider for Apple system integrations.
    let appleProvider: AppleProvider
    #endif

    /// Initializes the container and sets up the dependencies.
    /// For now, it creates a standard `OpenAIService`. In a testing environment,
    /// a mock service could be injected here.
    private init() {
        self.openAIService = OpenAIService()
        self.computerService = ComputerService()
        
        #if canImport(EventKit)
        self.eventKitPermissionManager = EventKitPermissionManager.shared
        self.appleCalendarRepository = AppleCalendarRepository()
        self.appleReminderRepository = AppleReminderRepository()
        let contactsPermissionManager = ContactsPermissionManager.shared
        let contactsRepository = ContactsRepository(permissionManager: contactsPermissionManager)
        self.appleProvider = AppleProvider(
            permissionManager: eventKitPermissionManager,
            calendarRepo: appleCalendarRepository,
            reminderRepo: appleReminderRepository,
            contactsPermissionManager: contactsPermissionManager,
            contactsRepo: contactsRepository
        )
        #endif
    }

    /// Creates a `ChatViewModel` with its required dependencies.
    /// - Returns: A fully configured `ChatViewModel`.
    @MainActor
    func makeChatViewModel() -> ChatViewModel {
        return ChatViewModel(api: openAIService, computerService: computerService)
    }
}
