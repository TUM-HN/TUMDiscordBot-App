import Charts
import SwiftData
import SwiftUI

// Chart data model
struct FeedbackChartData: Identifiable {
    let id = UUID()
    let category: String
    let count: Int
}

// Feedback Details View
struct FeedbackDetailsView: View {
    let fileName: String
    let groupName: String
    let date: String
    let preloadedFeedbacks: [FeedbackEntry]
    let preloadedChartData: [FeedbackChartData]

    @State private var selectedCategory: String? = nil
    @State private var showCategoryDetails = false
    @State private var isCategoryLoading = false
    @State private var filteredFeedbacks: [FeedbackEntry] = []

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                Group {
                    if preloadedFeedbacks.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "chart.bar.xaxis")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)

                            Text("No feedback found")
                                .font(.title2)
                                .foregroundColor(.gray)
                        }
                    } else {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 20) {
                                // Chart title
                                Text("Tutor Session Feedback")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .padding(.horizontal)
                                    .padding(.top, 8)

                                // Chart view
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Response Distribution")
                                        .font(.headline)
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal)

                                    Chart {
                                        ForEach(preloadedChartData) { item in
                                            BarMark(
                                                x: .value(
                                                    "Category",
                                                    item.category
                                                ),
                                                y: .value("Count", item.count)
                                            )
                                            .foregroundStyle(
                                                barColor(for: item.category)
                                            )
                                            .cornerRadius(6)
                                        }
                                    }
                                    .frame(height: 280)
                                    .padding(.vertical)
                                    .padding(.horizontal)
                                    .background(Color(.systemBackground))
                                    .cornerRadius(12)
                                    .shadow(
                                        color: Color.black.opacity(0.05),
                                        radius: 5,
                                        x: 0,
                                        y: 2
                                    )
                                    .padding(.horizontal)
                                    .chartYAxis {
                                        AxisMarks(position: .leading) {
                                            AxisValueLabel()
                                        }
                                    }
                                }

                                // Legend/summary with clickable categories
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Response Summary")
                                        .font(.headline)
                                        .foregroundColor(.secondary)
                                        .padding(.bottom, 4)

                                    ForEach(preloadedChartData) { item in
                                        if item.count > 0 {
                                            Button(action: {
                                                loadCategoryDetails(
                                                    for: item.category
                                                )
                                            }) {
                                                HStack {
                                                    RoundedRectangle(
                                                        cornerRadius: 4
                                                    )
                                                    .fill(
                                                        barColor(
                                                            for: item.category
                                                        )
                                                    )
                                                    .frame(
                                                        width: 16,
                                                        height: 16
                                                    )

                                                    Text(item.category)
                                                        .font(.subheadline)
                                                        .foregroundColor(
                                                            .primary
                                                        )

                                                    Spacer()

                                                    if isCategoryLoading
                                                        && selectedCategory
                                                            == item.category
                                                    {
                                                        ProgressView()
                                                            .scaleEffect(0.7)
                                                    } else {
                                                        Text(
                                                            "\(item.count) \(item.count == 1 ? "person" : "people")"
                                                        )
                                                        .font(.subheadline)
                                                        .foregroundColor(
                                                            .secondary
                                                        )

                                                        Image(
                                                            systemName:
                                                                "chevron.right"
                                                        )
                                                        .font(.caption)
                                                        .foregroundColor(
                                                            .secondary
                                                        )
                                                    }
                                                }
                                                .padding(.vertical, 4)
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                            .disabled(isCategoryLoading)
                                        }
                                    }
                                }
                                .padding()
                                .background(Color(.systemBackground))
                                .cornerRadius(12)
                                .shadow(
                                    color: Color.black.opacity(0.05),
                                    radius: 5,
                                    x: 0,
                                    y: 2
                                )
                                .padding(.horizontal)

                                // Total responses
                                HStack {
                                    Spacer()
                                    Text(
                                        "Total Responses: \(preloadedFeedbacks.count)"
                                    )
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                                    Spacer()
                                }
                                .padding(.top, 8)
                                .padding(.bottom, 24)
                            }
                            .padding(.vertical)
                        }
                    }
                }
            }
            .navigationTitle("\(groupName) - \(date)")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showCategoryDetails) {
                if let category = selectedCategory {
                    CategoryDetailsView(
                        category: category,
                        feedbacks: filteredFeedbacks,
                        color: barColor(for: category)
                    )
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                }
            }
        }
    }

    private func loadCategoryDetails(for category: String) {
        isCategoryLoading = true
        selectedCategory = category
        filteredFeedbacks = []

        // Use a small delay to show the loading indicator
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Filter feedbacks by the selected category, using case-insensitive comparison
            filteredFeedbacks = preloadedFeedbacks.filter {
                $0.Feedback.lowercased() == category.lowercased()
            }

            isCategoryLoading = false
            showCategoryDetails = true
        }
    }

    private func barColor(for category: String) -> Color {
        switch category {
        case "Good": return .green
        case "Satisfactory": return .orange
        case "Poor": return .red
        default: return .gray
        }
    }
}

// View for displaying people who selected a specific category
struct CategoryDetailsView: View {
    let category: String
    let feedbacks: [FeedbackEntry]
    let color: Color

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack {
                // Header
                HStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: 20, height: 20)

                    Text(category)
                        .font(.headline)
                        .padding(.leading, 4)

                    Spacer()

                    Text(
                        "\(feedbacks.count) \(feedbacks.count == 1 ? "person" : "people")"
                    )
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                .padding(.horizontal)
                .padding(.top)

                // List of people
                if feedbacks.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "person.slash")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)

                        Text("No people found with this response")
                            .font(.title3)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                } else {
                    List {
                        ForEach(feedbacks, id: \.Name) { feedback in
                            HStack(spacing: 12) {
                                Text(feedback.Name)
                                    .font(.body)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("People with \(category) Feedback")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct TutorFeedbackCommandView: View {
    @Bindable var bot: Bot
    @Environment(\.modelContext) private var context

    @State private var selectedGroup: String = ""
    @State private var selectedChannelId: String?
    @State private var channels: [Channel] = []
    @State private var isLoading = false
    @State private var isProcessing = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    @State private var showFeedback = false
    @State private var feedbackDuration: Double = 60  // Default 60 seconds

    @State private var feedbackFiles: [FeedbackFile] = []
    @State private var isFilesLoading = false
    @State private var feedbackCounts: [String: Int] = [:]
    @State private var loadingFiles: Set<String> = []
    @State private var selectedFile: FeedbackFile?
    @State private var showDetails = false
    @State private var isDetailDataLoading = false
    @State private var loadedFeedbacks: [FeedbackEntry] = []
    @State private var loadedChartData: [FeedbackChartData] = []

    // Compute valid groups from the bot model
    private var validGroups: [GroupModel] {
        return bot.groups.filter { $0.isValid }
    }

    // Get the selected group
    private var selectedGroupModel: GroupModel? {
        guard !selectedGroup.isEmpty else { return nil }
        return validGroups.first { $0.name == selectedGroup }
    }

    // Format duration as MM:ss
    private var formattedDuration: String {
        let minutes = Int(feedbackDuration) / 60
        let seconds = Int(feedbackDuration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var body: some View {
        Form {
            Section(header: RequiredSectionHeader(text: "Feedback Configuration")) {
                if validGroups.isEmpty {
                    Text(
                        "No valid groups available. Please add groups in Settings."
                    )
                    .foregroundColor(.red)
                    .font(.caption)
                } else {
                    Picker("Select Group", selection: $selectedGroup) {
                        Text("Select a group").tag("")
                        ForEach(validGroups, id: \.name) { group in
                            Text(group.name).tag(group.name)
                        }
                    }
                    .pickerStyle(.menu)
                }

                if isLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                            .padding()
                        Spacer()
                    }
                } else {
                    Picker("Select Channel", selection: $selectedChannelId) {
                        Text("Select a channel").tag(nil as String?)
                        ForEach(channels.filter { $0.type == "text" }) {
                            channel in
                            Text(channel.name).tag(channel.id as String?)
                        }
                    }
                    .pickerStyle(.menu)
                }

                HStack {
                    Text("Duration: \(formattedDuration)")
                    Spacer()
                    Text("\(Int(feedbackDuration)) sec")
                        .foregroundColor(.gray)
                        .font(.caption)
                }

                Slider(
                    value: $feedbackDuration,
                    in: 30...300,
                    step: 5
                ) {
                    Text("Feedback Duration")
                } minimumValueLabel: {
                    Text("30s")
                        .font(.caption)
                } maximumValueLabel: {
                    Text("5m")
                        .font(.caption)
                }

                if !bot.isActive {
                    Text("Bot must be active to use this command")
                        .foregroundColor(.red)
                        .font(.caption)
                }

                Button(isProcessing ? "Processing..." : "Start Feedback") {
                    startTutorFeedback()
                }
                .disabled(
                    selectedGroup.isEmpty || isProcessing || !bot.isActive
                        || selectedChannelId == nil
                )
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 5)
            }

            if showFeedback {
                Section {
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
                .listRowInsets(
                    EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16)
                )
            }

            Section(header: Text("Feedback Files")) {
                if isFilesLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                            .padding()
                        Spacer()
                    }
                } else if feedbackFiles.isEmpty {
                    Text("No feedback files available")
                        .foregroundColor(.gray)
                        .font(.caption)
                } else {

                    List {
                        ForEach(feedbackFiles) { file in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(extractGroupName(from: file.name))
                                        .font(.headline)

                                    Spacer()

                                    if loadingFiles.contains(file.name) {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                    } else {
                                        Text(
                                            "\(feedbackCounts[file.name] ?? 0) feedbacks"
                                        )
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    }
                                }

                                if let formattedDate = formatDate(
                                    from: file.name
                                ) {
                                    Text(formattedDate)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .frame(
                                maxWidth: .infinity,
                                maxHeight: .infinity,
                                alignment: .leading
                            )
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(
                                        Color(.systemGray4),
                                        lineWidth: 1
                                    )
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                loadFeedbackDetails(for: file)
                            }
                            .onAppear {
                                loadFeedbackCount(for: file.name)
                            }
                            .listRowSeparator(.hidden)
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: 500)
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: .infinity,
                        alignment: .leading
                    )
                    .listStyle(PlainListStyle())
                    .background(Color(.white))
                    .cornerRadius(10)
                    .padding(.vertical, 8)

                    if isDetailDataLoading {
                        HStack {
                            Spacer()
                            VStack {
                                ProgressView()
                                Text("Loading feedback data...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.top, 4)
                            }
                            Spacer()
                        }
                        .padding()
                    }
                }
            }
            .listRowInsets(
                EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16)
            )
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Tutor Feedback")
        .sheet(isPresented: $showDetails) {
            if let file = selectedFile,
                let formattedDate = formatDate(from: file.name)
            {
                FeedbackDetailsView(
                    fileName: file.name,
                    groupName: extractGroupName(from: file.name),
                    date: formattedDate,
                    preloadedFeedbacks: loadedFeedbacks,
                    preloadedChartData: loadedChartData
                )
                .presentationDragIndicator(.visible)
                .presentationDetents([.medium, .large])
            }
        }
        .onAppear {
            // Initialize the group if there are valid groups available
            if let firstGroup = validGroups.first {
                selectedGroup = firstGroup.name
            }
            fetchChannels()
            loadFeedbackFiles()
        }
        .refreshable {
            fetchChannels()
            loadFeedbackFiles()
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

    private func startTutorFeedback() {
        guard !selectedGroup.isEmpty else {
            errorMessage = "Please select a group."
            showFeedback = true
            return
        }

        guard let channelId = selectedChannelId else {
            errorMessage = "Please select a channel."
            showFeedback = true
            return
        }

        guard bot.isActive else {
            errorMessage = "Bot must be active to use this command."
            showFeedback = true
            return
        }

        isProcessing = true
        errorMessage = nil
        successMessage = nil
        showFeedback = false

        Task {
            // Construct the URL with parameters
            var urlComponents = URLComponents(
                string: "\(bot.apiClient.serverIP)/api/tutor-session-feedback"
            )
            let queryItems = [
                URLQueryItem(name: "api_key", value: bot.apiClient.apiKey),
                URLQueryItem(
                    name: "group_id",
                    value: selectedGroup.lowercased()
                ),
                URLQueryItem(name: "channel_id", value: channelId),
                URLQueryItem(
                    name: "duration",
                    value: "\(Int(feedbackDuration))"
                ),
            ]

            urlComponents?.queryItems = queryItems

            guard let url = urlComponents?.url else {
                DispatchQueue.main.async {
                    isProcessing = false
                    errorMessage = "Invalid URL"
                    showFeedback = true
                }
                return
            }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"

            do {
                let (data, response) = try await URLSession.shared.data(
                    for: request
                )

                DispatchQueue.main.async {
                    isProcessing = false
                    showFeedback = true

                    do {
                        // Try to decode the JSON response
                        struct FeedbackResponse: Codable {
                            let status: String
                            let message: String
                        }

                        let feedbackResponse = try JSONDecoder().decode(
                            FeedbackResponse.self,
                            from: data
                        )

                        if feedbackResponse.status == "success" {
                            successMessage =
                                "Tutor feedback session started for \(formattedDuration)"
                        } else {
                            errorMessage = feedbackResponse.message
                        }
                    } catch {
                        // Fallback if JSON parsing fails
                        if let httpResponse = response as? HTTPURLResponse,
                            httpResponse.statusCode == 200
                        {
                            successMessage =
                                "Tutor feedback session started for \(formattedDuration)"
                        } else {
                            errorMessage =
                                "Failed to start tutor feedback session. Server returned an unexpected response."
                        }
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    isProcessing = false
                    errorMessage = "Error: \(error.localizedDescription)"
                    showFeedback = true
                }
            }
        }
    }

    private func loadFeedbackFiles() {
        isFilesLoading = true
        errorMessage = nil

        Task {
            let result = await bot.apiClient.fetchFeedbackFiles()

            DispatchQueue.main.async {
                isFilesLoading = false

                switch result {
                case .success(let files):
                    // Sort files by creation date in descending order (newest first)
                    self.feedbackFiles = files.sorted {
                        guard
                            let date1 = ISO8601DateFormatter().date(
                                from: $0.created
                            ),
                            let date2 = ISO8601DateFormatter().date(
                                from: $1.created
                            )
                        else {
                            return false
                        }
                        return date1 > date2
                    }
                case .failure(let message):
                    self.errorMessage =
                        "Failed to load feedback files: \(message)"
                    self.showFeedback = true
                }
            }
        }
    }

    private func loadFeedbackCount(for fileName: String) {
        guard !loadingFiles.contains(fileName) else { return }

        loadingFiles.insert(fileName)

        Task {
            let result = await bot.apiClient.fetchFeedbackContent(
                fileName: fileName
            )

            DispatchQueue.main.async {
                loadingFiles.remove(fileName)

                switch result {
                case .success(let content):
                    feedbackCounts[fileName] = content.count
                case .failure(let message):
                    print(
                        "Failed to load feedback count for \(fileName): \(message)"
                    )
                    feedbackCounts[fileName] = 0
                }
            }
        }
    }

    private func loadFeedbackDetails(for file: FeedbackFile) {
        isDetailDataLoading = true
        selectedFile = file
        loadedFeedbacks = []
        loadedChartData = []

        Task {
            let result = await bot.apiClient.fetchFeedbackContent(
                fileName: file.name
            )

            DispatchQueue.main.async {
                isDetailDataLoading = false

                switch result {
                case .success(let content):
                    self.loadedFeedbacks = content

                    // Prepare chart data
                    self.loadedChartData = prepareChartData(from: content)

                    // Now that we have the data, show the details view
                    self.showDetails = true

                case .failure(let message):
                    self.errorMessage =
                        "Failed to load feedback details: \(message)"
                    self.showFeedback = true
                }
            }
        }
    }

    private func prepareChartData(from feedbacks: [FeedbackEntry])
        -> [FeedbackChartData]
    {
        var categoryCounts: [String: Int] = [:]

        // Process all responses
        for feedback in feedbacks {
            let category = feedback.Feedback
            categoryCounts[category, default: 0] += 1
        }

        // Define the order of categories
        let feedbackOrder = ["Good", "Satisfactory", "Poor"]

        // Convert dictionary to array and sort properly
        return feedbackOrder.map { category in
            // Find exact match or case-insensitive match
            let count =
                categoryCounts[category] ?? categoryCounts.first {
                    $0.key.lowercased() == category.lowercased()
                }?.value ?? 0
            return FeedbackChartData(category: category, count: count)
        }
    }

    // Format date from filename
    private func formatDate(from filename: String) -> String? {
        // Extract date parts from filename (e.g., g2_2025-04-28_13-56.csv)
        let components = filename.split(separator: "_")
        guard components.count >= 3 else { return nil }

        // Check if the third component contains time information
        let dateStr = String(components[1])
        let timeStr = components[2].replacingOccurrences(of: ".csv", with: "")

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        guard let date = dateFormatter.date(from: dateStr) else { return nil }

        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "EEE d MMMM"
        let formattedDate = outputFormatter.string(from: date)

        // Try to parse the time if it has the format HH-mm
        if timeStr.contains("-") {
            let timeComponents = timeStr.split(separator: "-")
            if timeComponents.count == 2,
                let hour = Int(timeComponents[0]),
                let minute = Int(timeComponents[1])
            {
                return
                    "\(formattedDate), \(hour):\(minute.formatted(.number.precision(.integerLength(2))))"
            }
        }

        return formattedDate
    }

    // Extract group name from filename
    private func extractGroupName(from filename: String) -> String {
        let components = filename.split(separator: "_")
        guard let groupName = components.first else { return filename }
        return String(groupName)  // Preserve original case
    }
}

#Preview {
    TutorFeedbackCommandView(bot: SampleData.shared.bot)
        .modelContainer(SampleData.shared.modelContainer)
}
