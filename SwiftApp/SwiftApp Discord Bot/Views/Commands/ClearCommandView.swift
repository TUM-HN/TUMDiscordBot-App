import SwiftData
import SwiftUI

struct ClearCommandView: View {
    @Bindable var bot: Bot

    @State private var selectedChannelId: String?
    @State private var messageLimit = 1
    @State private var channels: [Channel] = []
    @State private var isLoading = false
    @State private var isClearing = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    @State private var showFeedback = false

    // Available message limits
    let maxLimit = 10

    var body: some View {
        Form {
            Section(header: Text("Clear Command")) {
                if isLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                            .padding()
                        Spacer()
                    }
                } else {
                    Text("Delete messages from a Discord channel")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    // Channel selection
                    Picker("Channel", selection: $selectedChannelId) {
                        Text("Select a channel").tag(nil as String?)
                        ForEach(channels.filter { $0.type == "text" }) {
                            channel in
                            Text(channel.name).tag(channel.id as String?)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())

                    // Message limit selection with stepper
                    HStack {
                        Text("Number of Messages: \(messageLimit)")
                        Spacer()
                        Stepper("", value: $messageLimit, in: 1...maxLimit)
                            .labelsHidden()
                    }


                    // Warning text
                    Text(
                        "⚠️ This action cannot be undone. Messages will be permanently deleted."
                    )
                    .font(.caption)
                    .foregroundColor(.orange)
                    .padding(.top, 4)

                    // Clear button
                    Button(isClearing ? "Clearing..." : "Clear Messages") {
                        clearMessages()
                    }
                    .disabled(selectedChannelId == nil || isClearing)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
                    .foregroundColor(.red)
                }
            }

            if showFeedback {
                if let success = successMessage {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text(success)
                            .foregroundColor(.green)
                    }
                    .padding(.vertical, 5)
                }

                if let error = errorMessage {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        Text(error)
                            .foregroundColor(.red)
                    }
                    .padding(.vertical, 5)
                }
            }
        }
        .navigationTitle("Clear Messages")
        .onAppear {
            fetchChannels()
        }
        .refreshable {
            fetchChannels()
        }
    }

    private func fetchChannels() {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        showFeedback = false

        Task {
            let result = await bot.apiClient.fetchChannels()

            DispatchQueue.main.async {
                isLoading = false

                switch result {
                case .success(let fetchedChannels):
                    self.channels = fetchedChannels.sorted {
                        $0.position < $1.position
                    }
                case .failure(let error):
                    self.errorMessage = "Failed to load channels: \(error)"
                    self.showFeedback = true
                }
            }
        }
    }

    private func clearMessages() {
        guard let channelId = selectedChannelId else { return }

        isClearing = true
        errorMessage = nil
        successMessage = nil
        showFeedback = false

        Task {
            let result = await bot.apiClient.clearMessages(
                channelId: channelId,
                limit: messageLimit
            )

            DispatchQueue.main.async {
                isClearing = false
                showFeedback = true

                switch result {
                case .success(let message):
                    successMessage = message
                case .failure(let message):
                    errorMessage = message
                }
            }
        }
    }
}

#Preview {
    ClearCommandView(bot: SampleData.shared.bot)
        .modelContainer(
            SampleData.shared.modelContainer
        )
}
