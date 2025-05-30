import SwiftData
import SwiftUI

struct BotView: View {
    @Bindable var bot: Bot

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header Info
                HeaderView(bot: bot)

                // Commands Section
                CommandsView(bot: bot)
            }
            .padding()
            .accessibilityIdentifier("botMainContent")
        }
        .background(Color.tumGray9)
        .accessibilityIdentifier("botMainView")
    }
}

#Preview {
    NavigationStack {
        BotView(bot: SampleData.shared.bot)
            .modelContainer(SampleData.shared.modelContainer)
    }
}
