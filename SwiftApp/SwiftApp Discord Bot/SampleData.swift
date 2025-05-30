import Foundation
import SwiftData

@MainActor
class SampleData {
    static let shared = SampleData()

    let modelContainer: ModelContainer
    private let defaultBot: Bot

    var context: ModelContext {
        modelContainer.mainContext
    }

    var bot: Bot {
        defaultBot
    }

    init() {
        // Create the default bot
        defaultBot = Bot(
            name: "Bot",
            apiClient: APIClient(serverIP: "http://127.0.0.1:5000", apiKey: "025002"),
            token: "",
            devToken: ""
        )
        
        // Set up the model container
        let schema = Schema([Bot.self])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )

        do {
            modelContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
            
            // Insert the default bot
            context.insert(defaultBot)
            try context.save()
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
}
