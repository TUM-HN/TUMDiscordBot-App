import SwiftData
import SwiftUI

struct SettingsView: View {
    @Bindable var bot: Bot

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @State private var serverIP: String
    @State private var apiKey: String
    @State private var isEditingServer = false
    @State private var isEditingManagement = false
    @State private var roles: [AccessRole] = []
    @State private var showConfirmationDialog = false

    @State private var isLoading = false
    @State private var isLoadingSettings = false
    @State private var isServerOnline = true // New state to track server connectivity
    @State private var isAssigning = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    @State private var showFeedback = false
    
    // States for saving management settings
    @State private var isSavingManagement = false
    @State private var managementSaveSuccess = false
    
    // Bot configuration
    @State private var token: String
    @State private var devToken: String
    @State private var isDeveloperMode: Bool
    
    // Groups configuration
    @State private var numberOfGroups = 2
    @State private var groups: [GroupConfig] = []
    
    // Available number of groups
    let groupOptions = Array(1...10)

    init(bot: Bot) {
        self.bot = bot
        // Initialize state values from the Bot's API client
        _serverIP = State(
            initialValue: bot.apiClient?.serverIP ?? "http:/127.0.0.1:5000"
        )
        _apiKey = State(
            initialValue: bot.apiClient?.apiKey ?? "your-api-key-here"
        )
        
        // Initialize bot token settings
        _token = State(initialValue: bot.token ?? "")
        _devToken = State(initialValue: bot.devToken ?? "")
        _isDeveloperMode = State(initialValue: bot.isDeveloperMode)
        
        // Initialize groups from bot's persisted groups
        var initialGroups: [GroupConfig] = []
        
        if !bot.groups.isEmpty {
            // Use the saved groups if available
            for group in bot.groups {
                initialGroups.append(GroupConfig(name: group.name, isValid: group.isValid))
            }
            print("DEBUG: Loaded \(initialGroups.count) groups from persistent storage")
        } else {
            // Only use placeholder groups if no saved groups exist
            initialGroups = [GroupConfig(name: "G1", isValid: true), GroupConfig(name: "G2", isValid: true)]
            print("DEBUG: No saved groups found, using placeholders")
        }
        
        _groups = State(initialValue: initialGroups)
        _numberOfGroups = State(initialValue: initialGroups.count)
    }

    var body: some View {
        NavigationStack {
            if bot.isActive {
                // Show only this when bot is running, instead of any settings
                VStack {
                    Spacer()
                    
                    VStack(spacing: 20) {
                        Image(systemName: "bolt.fill")
                            .foregroundColor(Color.tumGreen)
                            .font(.system(size: 50))
                        
                        Text("Bot is Running")
                            .foregroundColor(Color.tumGreen)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Settings cannot be modified while the bot is running.")
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                        
                        Text("To modify settings, please stop the bot first.")
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                            .padding(.bottom, 10)
                    }
                    .padding()
                    .background(Color.tumGray8.opacity(0.5))
                    .cornerRadius(16)
                    .padding(.horizontal, 30)
                    
                    Spacer()
                }
                .navigationTitle("Settings")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
            } else {
                // Only show settings when bot is not running
                Form {
                    Section(header: Text("Server Settings")) {
                        if isEditingServer {
                            TextField("Server IP", text: $serverIP)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .font(.body)
                                .accessibilityIdentifier("serverIPField")

                            TextField("API Key", text: $apiKey)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .font(.body)
                                .accessibilityIdentifier("apiKeyField")
                            
                            Button("Save Server Settings") {
                                saveServerSettings()
                                isEditingServer = false
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                            .foregroundColor(Color.tumBlue)
                            .accessibilityIdentifier("saveServerSettingsButton")
                        } else {
                            HStack {
                                Text("Server IP")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(serverIP)
                                    .foregroundColor(.primary)
                                    .accessibilityIdentifier("serverIPValue")
                            }

                            HStack {
                                Text("API Key")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(apiKey)
                                    .foregroundColor(.primary)
                                    .accessibilityIdentifier("apiKeyValue")
                            }
                            
                            Button("Edit Server Settings") {
                                isEditingServer = true
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                            .foregroundColor(Color.tumBlue)
                            .accessibilityIdentifier("editServerSettingsButton")
                        }
                    }
                    
                    // Combined Management section
                    Section(header: Text("Management")) {
                        if isLoadingSettings {
                            HStack {
                                Spacer()
                                ProgressView()
                                    .padding(.vertical, 20)
                                Spacer()
                            }
                        } else if !isServerOnline {
                            // Only show this when server is offline
                            VStack {
                                HStack {
                                    Spacer()
                                    Image(systemName: "wifi.slash")
                                        .foregroundColor(Color.tumRed)
                                        .imageScale(.large)
                                    Text("Server Offline")
                                        .foregroundColor(Color.tumRed)
                                        .font(.headline)
                                    Spacer()
                                }
                                .padding(.vertical, 10)
                                
                                Text("Management settings cannot be modified while the server is offline. To access and modify these settings, please connect to the server by configuring the Server Settings. Make sure it is running")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.bottom, 10)
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }
                        } else {
                            // Only show all settings content when server is online
                            
                            // Bot Settings subsection
                            Text("Bot Settings")
                                .font(.headline)
                                .padding(.top, 5)
                            
                            if isEditingManagement {
                                Toggle("Developer Mode", isOn: $isDeveloperMode)
                                    .tint(Color.tumBlue)
                                
                                if isDeveloperMode {
                                    TextField("Developer Token", text: $devToken)
                                        .textInputAutocapitalization(.never)
                                        .autocorrectionDisabled()
                                        .font(.body)
                                        .foregroundColor(Color.tumOrange)
                                } else {
                                    TextField("Bot Token", text: $token)
                                        .textInputAutocapitalization(.never)
                                        .autocorrectionDisabled()
                                        .font(.body)
                                }
                            } else {
                                HStack {
                                    Text("Developer Mode")
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(isDeveloperMode ? "Enabled" : "Disabled")
                                        .foregroundColor(isDeveloperMode ? Color.tumOrange : .primary)
                                }
                                
                                HStack {
                                    Text(isDeveloperMode ? "Developer Token" : "Bot Token")
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(isDeveloperMode ? 
                                        (devToken.isEmpty ? "Not set" : "••••••••••••••••") : 
                                        (token.isEmpty ? "Not set" : "••••••••••••••••"))
                                        .foregroundColor(isDeveloperMode ? Color.tumOrange : .primary)
                                }
                            }
                            
                            // Groups management subsection
                            Text("Groups Management")
                                .font(.headline)
                                .padding(.bottom, 5)
                            
                            if isEditingManagement {
                                Picker("Number of Groups", selection: $numberOfGroups) {
                                    ForEach(groupOptions, id: \.self) { number in
                                        Text("\(number)").tag(number)
                                    }
                                }
                                .onChange(of: numberOfGroups) { oldValue, newValue in
                                    updateGroups(count: newValue)
                                }
                                
                                ForEach(0..<groups.count, id: \.self) { index in
                                    VStack(alignment: .leading) {
                                        Text("Group \(index + 1)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        
                                        HStack {
                                            TextField("Enter group name", text: $groups[index].name)
                                            
                                            Picker("", selection: $groups[index].isValid) {
                                                Text("Invalid").tag(false)
                                                Text("Valid").tag(true)
                                            }
                                            .pickerStyle(.menu)
                                            .frame(width: 110)
                                        }
                                    }
                                    .padding(.vertical, 4)
                                }
                                
                                if isSavingManagement {
                                    HStack {
                                        Spacer()
                                        ProgressView()
                                            .padding(.trailing, 10)
                                        Text("Saving settings...")
                                        Spacer()
                                    }
                                    .padding(.vertical, 10)
                                } else {
                                    Button("Save Management Settings") {
                                        saveManagementSettings()
                                    }
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .foregroundColor(Color.tumBlue)
                                }
                                
                                if managementSaveSuccess {
                                    HStack {
                                        Spacer()
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(Color.tumGreen)
                                        Text("Successfully Saved")
                                            .foregroundColor(Color.tumGreen)
                                        Spacer()
                                    }
                                    .padding(.vertical, 5)
                                }
                                
                                if let error = errorMessage, isServerOnline {
                                    HStack {
                                        Spacer()
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .foregroundColor(Color.tumRed)
                                        Text(error)
                                            .foregroundColor(Color.tumRed)
                                        Spacer()
                                    }
                                    .padding(.vertical, 5)
                                }
                            } else {
                                // Display groups in non-editing mode
                                ForEach(groups.indices, id: \.self) { index in
                                    HStack {
                                        Text(groups[index].name)
                                            .foregroundColor(.primary)
                                        Spacer()
                                        Text(groups[index].isValid ? "Valid" : "Invalid")
                                            .foregroundColor(groups[index].isValid ? Color.tumGreen : Color.tumGray4)
                                    }
                                }
                                
                                if isServerOnline {
                                    Button("Edit Management Settings") {
                                        isEditingManagement = true
                                        // Reset status flags when starting to edit
                                        managementSaveSuccess = false
                                        errorMessage = nil
                                    }
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .foregroundColor(Color.tumBlue)
                                }
                            }
                        }
                    }
                    .disabled(isLoadingSettings || !isServerOnline)
                }
                .navigationTitle("Settings")
                .navigationBarTitleDisplayMode(.inline)
                .accessibilityIdentifier("settingsView")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") {
                            if isEditingServer || isEditingManagement {
                                showConfirmationDialog = true
                            } else {
                                dismiss()
                            }
                        }
                        .accessibilityIdentifier("doneButton")
                        .confirmationDialog(
                            "Are you sure you want to discard your changes?",
                            isPresented: $showConfirmationDialog,
                            titleVisibility: .visible
                        ) {
                            Button("Discard Changes", role: .destructive) {
                                isEditingServer = false
                                isEditingManagement = false
                                dismiss()
                            }
                            Button("Cancel", role: .cancel) {
                                // Simply dismisses the dialog
                            }
                        }
                    }
                }
            }
        }
        .presentationDragIndicator(.visible)
        .onAppear {
            fetchSettingsFromServer()
        }
    }
    
    private func saveServerSettings() {
        // If APIClient doesn't exist, create one
        if bot.apiClient == nil {
            bot.apiClient = APIClient(
                serverIP: serverIP,
                apiKey: apiKey
            )
        } else {
            // Update existing APIClient
            bot.apiClient?.serverIP = serverIP
            bot.apiClient?.apiKey = apiKey
        }
        
        // Save changes to the model context
        do {
            try context.save()
            print("DEBUG: Server settings saved to persistent storage")
            
            // Fetch settings from server after saving server connection details
            fetchSettingsFromServer()
        } catch {
            print("DEBUG: Failed to save server settings: \(error)")
        }
    }
    
    private func fetchSettingsFromServer() {
        guard let apiClient = bot.apiClient else {
            print("DEBUG: Cannot fetch settings - API client not initialized")
            isServerOnline = false
            return
        }
        
        isLoadingSettings = true
        errorMessage = nil
        // Reset server online status when starting the fetch
        isServerOnline = true
        
        Task {
            do {
                // Check if server is online first
                let isOnline = await apiClient.checkServerStatus()
                
                if !isOnline {
                    await MainActor.run {
                        errorMessage = "Server is offline. Using saved settings."
                        print("DEBUG: Server is offline. Using saved settings.")
                        isLoadingSettings = false
                        isServerOnline = false
                    }
                    return
                }
                
                // Fetch settings
                let result = await apiClient.fetchSettings()
                
                // Process the result on main thread
                await MainActor.run {
                    switch result {
                    case .success(let settings):
                        // Update UI with fetched settings
                        updateUIWithSettings(settings)
                        print("DEBUG: Settings updated from server successfully")
                        isServerOnline = true
                    case .failure(let error):
                        errorMessage = "Failed to fetch settings: \(error.localizedDescription)"
                        print("DEBUG: \(errorMessage ?? "")")
                        // Keep server online state true since the server responded, just with an error
                        isServerOnline = true
                    }
                    isLoadingSettings = false
                }
            } catch {
                // Handle errors
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    print("DEBUG: Error fetching settings: \(error)")
                    isLoadingSettings = false
                    isServerOnline = false
                }
            }
        }
    }
    
    private func updateUIWithSettings(_ settings: BotSettings) {
        // Update developer mode and tokens
        isDeveloperMode = settings.developmentMode
        token = settings.token
        devToken = settings.devToken
        
        // Update roles
        roles = settings.accessRoles
        
        // Update groups
        updateGroupsFromServerData(settings.groups)
        
        // Update the bot object
        bot.isDeveloperMode = settings.developmentMode
        bot.token = settings.token
        bot.devToken = settings.devToken
        
        // Save to context
        do {
            try context.save()
        } catch {
            print("DEBUG: Failed to save settings to model: \(error)")
        }
    }
    
    private func updateGroupsFromServerData(_ serverGroups: [String]) {
        // Create new groups based on server data
        groups = []
        for groupName in serverGroups {
            groups.append(GroupConfig(name: groupName, isValid: true))
        }
        
        // Update number of groups
        numberOfGroups = groups.count
        
        // Save these groups to the bot model for persistence
        updateBotGroups()
        
        print("DEBUG: Updated groups from server: \(groups.map { $0.name })")
    }
    
    private func saveManagementSettings() {
        // Start loading state
        isSavingManagement = true
        managementSaveSuccess = false
        errorMessage = nil
        
        Task {
            do {
                guard let apiClient = bot.apiClient else {
                    throw NSError(domain: "SettingsError", code: 0, userInfo: [NSLocalizedDescriptionKey: "API client not initialized"])
                }
                
                // Check if server is online first
                let isOnline = await apiClient.checkServerStatus()
                
                if !isOnline {
                    await MainActor.run {
                        errorMessage = "Server is offline. Cannot save settings."
                        isServerOnline = false
                        isSavingManagement = false
                    }
                    return
                }
                
                // Step 1: Update development mode
                let devModeResult = await apiClient.updateDevelopmentMode(isDeveloperMode)
                switch devModeResult {
                case .failure(let message):
                    throw NSError(domain: "SettingsError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to update development mode: \(message)"])
                case .success:
                    print("DEBUG: Development mode updated successfully")
                }
                
                // Step 2: Update the appropriate token based on development mode
                let tokenToUse = isDeveloperMode ? devToken : token
                let tokenResult = await apiClient.updateBotToken(isDeveloperMode: isDeveloperMode, token: tokenToUse)
                switch tokenResult {
                case .failure(let message):
                    throw NSError(domain: "SettingsError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to update bot token: \(message)"])
                case .success:
                    print("DEBUG: Bot token updated successfully")
                }
                
                // Step 3: Update groups on the server
                let groupNames = groups.map { $0.name }
                let groupsResult = await apiClient.updateGroups(groups: groupNames)
                switch groupsResult {
                case .failure(let message):
                    throw NSError(domain: "SettingsError", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to update groups: \(message)"])
                case .success:
                    print("DEBUG: Groups updated successfully")
                }
                
                // Update local model
                bot.token = token
                bot.devToken = devToken
                bot.isDeveloperMode = isDeveloperMode
                
                // Update groups in the bot model
                updateBotGroups()
                
                // Save changes to the model context
                do {
                    try context.save()
                    print("DEBUG: Management settings saved to persistent storage")
                } catch {
                    throw NSError(domain: "SettingsError", code: 4, userInfo: [NSLocalizedDescriptionKey: "Failed to save settings to persistent storage: \(error.localizedDescription)"])
                }
                
                // Update UI on main thread
                DispatchQueue.main.async {
                    isSavingManagement = false
                    managementSaveSuccess = true
                    isEditingManagement = false
                    isServerOnline = true
                    
                    // Auto-hide the success message after 3 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        withAnimation {
                            managementSaveSuccess = false
                        }
                    }
                }
            } catch {
                // Handle errors
                DispatchQueue.main.async {
                    isSavingManagement = false
                    errorMessage = error.localizedDescription
                    // Keep server online state true since we got a response from the server
                    isServerOnline = true
                }
            }
        }
    }
    
    private func updateGroups(count: Int) {
        // Keep existing groups up to the new count
        if count <= groups.count {
            groups = Array(groups.prefix(count))
        } else {
            // Add new groups up to the requested count
            let additionalGroups = (groups.count..<count).map { index in 
                GroupConfig(name: "Group \(index + 1)", isValid: false)
            }
            groups.append(contentsOf: additionalGroups)
        }
    }
    
    private func updateBotGroups() {
        print("DEBUG: Updating bot groups - count before: \(bot.groups.count)")
        
        // Create a copy of the existing groups to avoid modification during iteration
        let existingGroups = bot.groups
        
        // Remove all existing groups
        for group in existingGroups {
            context.delete(group)
        }
        bot.groups.removeAll()
        
        // Add new groups from the configuration
        for groupConfig in groups {
            let newGroup = GroupModel(name: groupConfig.name, isValid: groupConfig.isValid)
            bot.groups.append(newGroup)
        }
        
        print("DEBUG: Bot groups updated - new count: \(bot.groups.count)")
    }
}

// Temporary struct to hold group configuration
struct GroupConfig: Identifiable {
    var id = UUID()
    var name: String
    var isValid: Bool
}

// Preview for Settings View
#Preview("Settings") {
    SettingsView(bot: SampleData.shared.bot)
        .modelContainer(SampleData.shared.modelContainer)
}
