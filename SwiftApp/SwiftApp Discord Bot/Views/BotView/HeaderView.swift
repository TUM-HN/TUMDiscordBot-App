import SwiftData
import SwiftUI

struct HeaderView: View {
    @Bindable var bot: Bot
    @Environment(\.modelContext) private var context
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.dismiss) private var dismiss

    @State private var showSettings = false
    @State private var isServerActive = false
    @State private var counter = 0
    @State private var onlineMembers = 0
    @State private var offlineMembers = 0
    @State private var totalMembers = 0
    @State private var isLoadingBotAction = false
    @State private var serverResponseMessage = ""
    @State private var showServerResponseMessage = false
    @State private var isMessageSuccess = false
    @State private var showDeleteConfirmation = false

    let timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Top section with bot info and settings
            HStack(alignment: .center, spacing: 16) {
                Image(systemName: "laptopcomputer")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 60, maxHeight: 50)
                    .foregroundColor(.tumBlue)

                // Bot status and Server status
                VStack(alignment: .center, spacing: 8) {
                    Text("DiscordBot Manager")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.tumBlue)
                        .frame(maxWidth: .infinity, alignment: .center)

                    // Bot Status
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Circle()
                                .foregroundColor(bot.isActive ? .tumGreen : .tumGray4)
                                .frame(width: 10, height: 10)
                            Text(bot.isActive ? "Active" : "InActive")
                                .foregroundColor(bot.isActive ? .tumGreen : .tumGray4)
                                .font(.subheadline)
                                .accessibilityIdentifier("botStatusIndicator")
                            Circle()
                                .foregroundColor(isServerActive ? .tumGreen : .tumOrange)
                                .frame(width: 10, height: 10)
                            Text(isServerActive ? "Server Online" : "Server Offline")
                                .foregroundColor(isServerActive ? .tumGreen : .tumOrange)
                                .font(.subheadline)
                                .accessibilityIdentifier("serverStatusIndicator")
                        }

                        // Debug Info
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Server URL: \(bot.apiClient?.serverIP ?? "Unknown")")
                                .font(.caption)
                                .foregroundColor(.tumGray3)
                            Text("Status checks: \(counter)")
                                .font(.caption)
                                .foregroundColor(.tumGray3)
                        }
                    }
                }

                Button(action: {
                    showSettings = true
                }) {
                    Image(systemName: "gearshape")
                        .font(.title)
                        .foregroundColor(.tumBlue)
                }
                .accessibilityIdentifier("settings")
                .sheet(isPresented: $showSettings) {
                    SettingsView(bot: bot.self)
                        .presentationDetents([.medium, .large])
                        .presentationDragIndicator(.visible)
                }
            }
            .frame(maxWidth: .infinity)

            // Server Info and Controls
            HStack(spacing: 16) {
                serverStatsView
                controlsView
            }

            // Status messages
            if !isServerActive {
                Text("Server is offline. Cannot start/stop bot.")
                    .foregroundColor(.tumRed)
                    .font(.caption)
            }
            
            if showServerResponseMessage && !serverResponseMessage.isEmpty {
                Text(serverResponseMessage)
                    .foregroundColor(isMessageSuccess ? .tumGreen : .tumRed)
                    .font(.caption)
                    .padding(.top, 5)
                    .transition(.opacity)
            }
        }
        .padding()
        .background(Color.tumGray9.opacity(0.5))
        .cornerRadius(15)
        .onAppear {
            updateStatus()
        }
        .alert("Delete Bot", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                deleteBot()
            }
        } message: {
            Text("Are you sure you want to delete this bot? This action cannot be undone.")
        }
    }
    
    // Server Stats View
    private var serverStatsView: some View {
        VStack(alignment: .center, spacing: 8) {
            Text("Server Stats")
                .font(.headline)
                .padding(.bottom, 2)
                .frame(maxWidth: .infinity, alignment: .center)

            HStack(spacing: 6) {
                Spacer()
                VStack(spacing: 4) {
                    Text("\(onlineMembers)")
                        .font(.title2)
                        .foregroundColor(.tumGreen)
                        .frame(maxWidth: .infinity, alignment: .center)
                    Text("Online")
                        .font(.caption2)
                        .frame(maxWidth: .infinity, alignment: .center)
                }

                VStack(spacing: 4) {
                    Text("\(offlineMembers)")
                        .font(.title2)
                        .foregroundColor(.tumGray4)
                        .frame(maxWidth: .infinity, alignment: .center)
                    Text("Offline")
                        .font(.caption2)
                        .frame(maxWidth: .infinity, alignment: .center)
                }

                VStack(spacing: 4) {
                    Text("\(totalMembers)")
                        .font(.title2)
                        .foregroundColor(.tumBlue)
                        .frame(maxWidth: .infinity, alignment: .center)
                    Text("Total")
                        .font(.caption2)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                Spacer()
            }
        }
        .padding(.horizontal, 5)
        .padding(.vertical, 20)
        .background(Color.tumGray8)
        .cornerRadius(10)
        .frame(maxWidth: .infinity)
    }
    
    // Controls View
    private var controlsView: some View {
        VStack(spacing: 16) {
            // Delete button
            Button {
                showDeleteConfirmation = true
            } label: {
                HStack {
                    Image(systemName: "trash")
                    Text("Delete Bot")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .background(Color.tumRed)
            .foregroundColor(.white)
            .cornerRadius(10)
            .accessibilityIdentifier("deleteBotButton")
            .onReceive(timer) { _ in
                counter += 1
                updateStatus()
            }

            // Start/Stop bot button
            Button {
                if (!bot.isActive) {
                    startBot()
                } else {
                    stopBot()
                }
            } label: {
                HStack {
                    Image(systemName: bot.isActive ? "stop.fill" : "play.fill")
                    Text(bot.isActive ? "Stop Bot" : "Start Bot")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .background(bot.isActive ? Color.tumRed : Color.tumGreen)
            .foregroundColor(.white)
            .cornerRadius(10)
            .disabled(!isServerActive || isLoadingBotAction)
            .accessibilityIdentifier(bot.isActive ? "stopBotButton" : "startBotButton")
        }
        .frame(width: horizontalSizeClass == .regular ? 200 : 150)
    }
    
    private func deleteBot() {
        if !bot.isActive {
            context.delete(bot)
            try? context.save()
        } else {
            // If the bot is active, stop it first, then delete
            stopAndDeleteBot()
        }
    }
    
    private func stopAndDeleteBot() {
        // Set loading state
        isLoadingBotAction = true
        
        Task {
            do {
                // Create URL for the request
                guard let url = URL(string: "\(bot.apiClient?.serverIP ?? "")/api/stop-bot?api_key=\(bot.apiClient?.apiKey ?? "")") else {
                    throw URLError(.badURL)
                }
                
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                
                // Try to stop the bot first
                let (_, _) = try await URLSession.shared.data(for: request)
                
                // Once stopped (or even if it fails), delete the bot
                DispatchQueue.main.async {
                    isLoadingBotAction = false
                    context.delete(bot)
                    try? context.save()
                }
            } catch {
                // If there's an error stopping the bot, still delete it
                DispatchQueue.main.async {
                    isLoadingBotAction = false
                    context.delete(bot)
                    try? context.save()
                }
            }
        }
    }
    
    private func startBot() {
        // Set loading state
        isLoadingBotAction = true
        serverResponseMessage = ""
        showServerResponseMessage = false
        
        Task {
            do {
                guard let apiClient = bot.apiClient else {
                    throw NSError(domain: "BotError", code: 0, userInfo: [NSLocalizedDescriptionKey: "API client not initialized"])
                }
                
                // Start the bot - directly call the start-bot endpoint
                guard let url = URL(string: "\(bot.apiClient?.serverIP ?? "")/api/start-bot?api_key=\(bot.apiClient?.apiKey ?? "")") else {
                    throw URLError(.badURL)
                }
                
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                
                // Perform the request
                let (data, response) = try await URLSession.shared.data(for: request)
                
                // Process the response on the main thread
                DispatchQueue.main.async {
                    isLoadingBotAction = false
                    
                    // Parse JSON response regardless of status code
                    do {
                        if let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                           let status = jsonResponse["status"] as? String,
                           let message = jsonResponse["message"] as? String {
                            
                            if status == "success" {
                                bot.isActive = true
                                serverResponseMessage = message
                                isMessageSuccess = true
                            } else {
                                bot.isActive = false
                                serverResponseMessage = message
                                isMessageSuccess = false
                            }
                            
                            showServerResponseMessage = true
                            // Auto-hide the message after 3 seconds
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                withAnimation {
                                    showServerResponseMessage = false
                                }
                            }
                        } else {
                            // If we can't extract status and message, try to get the raw response
                            if let stringData = String(data: data, encoding: .utf8) {
                                bot.isActive = false
                                serverResponseMessage = "Unexpected response format: \(stringData)"
                                isMessageSuccess = false
                                showServerResponseMessage = true
                            } else {
                                bot.isActive = false
                                serverResponseMessage = "Failed to parse server response"
                                isMessageSuccess = false
                                showServerResponseMessage = true
                            }
                        }
                    } catch {
                        bot.isActive = false
                        serverResponseMessage = "Failed to parse response: \(error.localizedDescription)"
                        isMessageSuccess = false
                        showServerResponseMessage = true
                    }
                }
            } catch {
                // Handle network errors
                DispatchQueue.main.async {
                    isLoadingBotAction = false
                    bot.isActive = false
                    serverResponseMessage = "Network error: \(error.localizedDescription)"
                    isMessageSuccess = false
                    showServerResponseMessage = true
                }
            }
        }
    }
    
    private func stopBot() {
        // Set loading state
        isLoadingBotAction = true
        serverResponseMessage = ""
        showServerResponseMessage = false
        
        Task {
            do {
                // Create URL for the request
                guard let url = URL(string: "\(bot.apiClient?.serverIP ?? "")/api/stop-bot?api_key=\(bot.apiClient?.apiKey ?? "")") else {
                    throw URLError(.badURL)
                }
                
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                
                // Perform the request
                let (data, response) = try await URLSession.shared.data(for: request)
                
                // Process the response on the main thread
                DispatchQueue.main.async {
                    isLoadingBotAction = false
                    
                    // Parse JSON response regardless of status code
                    do {
                        if let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                           let status = jsonResponse["status"] as? String,
                           let message = jsonResponse["message"] as? String {
                            
                            if status == "success" {
                                bot.isActive = false
                                // Reset all group attendance statuses
                                resetAllAttendanceStatuses()
                                
                                serverResponseMessage = message
                                isMessageSuccess = true
                            } else {
                                serverResponseMessage = message
                                isMessageSuccess = false
                            }
                            
                            showServerResponseMessage = true
                            // Auto-hide the message after 3 seconds
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                withAnimation {
                                    showServerResponseMessage = false
                                }
                            }
                        } else {
                            // If we can't extract status and message, try to get the raw response
                            if let stringData = String(data: data, encoding: .utf8) {
                                serverResponseMessage = "Unexpected response format: \(stringData)"
                                isMessageSuccess = false
                                showServerResponseMessage = true
                            } else {
                                serverResponseMessage = "Failed to parse server response"
                                isMessageSuccess = false
                                showServerResponseMessage = true
                            }
                        }
                    } catch {
                        serverResponseMessage = "Failed to parse response: \(error.localizedDescription)"
                        isMessageSuccess = false
                        showServerResponseMessage = true
                    }
                }
            } catch {
                // Handle network errors
                DispatchQueue.main.async {
                    isLoadingBotAction = false
                    serverResponseMessage = "Network error: \(error.localizedDescription)"
                    isMessageSuccess = false
                    showServerResponseMessage = true
                }
            }
        }
    }

    private func updateStatus() {
        Task {
            // Perform the async operation for Server
            var isActive =
                await bot.apiClient?.checkServerStatus()
                ?? false

            // Update the state on the main thread
            DispatchQueue.main.async {
                isServerActive = isActive
            }

            // Perform the async operation for Bot
            isActive =
                await bot.apiClient?.checkBotStatus()
                ?? false
            
            // Store previous bot status to detect changes
            let previousBotStatus = bot.isActive
            
            DispatchQueue.main.async {
                bot.isActive = isActive
                
                // If bot status changed from active to inactive, reset attendance
                if previousBotStatus && !isActive {
                    resetAllAttendanceStatuses()
                }
            }
            
            // Fetch member count data
            if let result = await bot.apiClient?.fetchMemberCount() {
                DispatchQueue.main.async {
                    switch result {
                    case .success(let online, let offline, let total):
                        onlineMembers = online
                        offlineMembers = offline
                        totalMembers = total
                    case .failure:
                        // If bot is not running, set all counts to 0
                        onlineMembers = 0
                        offlineMembers = 0
                        totalMembers = 0
                    }
                }
            } else {
                // If API client is nil or any other issue
                DispatchQueue.main.async {
                    onlineMembers = 0
                    offlineMembers = 0
                    totalMembers = 0
                }
            }
        }
    }
    
    // Reset all group attendance statuses to inactive
    private func resetAllAttendanceStatuses() {
        for group in bot.groups {
            if group.attendanceActive {
                group.attendanceActive = false
            }
        }
        
        // Save changes to the model context
        try? context.save()
        
        print("DEBUG: All attendance statuses reset due to bot becoming inactive")
    }
}

#Preview {
    ScrollView {
        VStack(alignment: .leading, spacing: 20) {
            HeaderView(bot: SampleData.shared.bot)
        }
        .padding()
    }
    .background(Color(.systemBackground))
    .modelContainer(SampleData.shared.modelContainer)
}
