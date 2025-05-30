import SwiftUI

@main
struct DiscordApp_DemoApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(for: Bot.self, inMemory: false)
                .tint(.tumBlue) // Set the app's accent color to TUM blue
        }
    }
}
