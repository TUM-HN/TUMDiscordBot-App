import Charts
import SwiftData
import SwiftUI

// Chart data model
struct ChartData: Identifiable {
    let id = UUID()
    let category: String
    let count: Int
}

// View for displaying people who selected a specific category
struct SurveyCategoryDetailsView: View {
    let category: String
    let surveys: [SurveyEntry]
    let questionKey: String
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
                        "\(surveys.count) \(surveys.count == 1 ? "person" : "people")"
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
                if surveys.isEmpty {
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
                        ForEach(surveys, id: \.Name) { survey in
                            HStack(spacing: 12) {
                                Text(survey.Name)
                                    .font(.body)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("People who answered \(category)")
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

// Survey Details View with Chart
struct SurveyDetailsView: View {
    let fileName: String
    let topic: String
    let date: String
    let preloadedSurveys: [SurveyEntry]
    let preloadedChartData: [ChartData]
    let preloadedQuestionKey: String
    let isPercentageData: Bool

    @State private var selectedCategory: String? = nil
    @State private var showCategoryDetails = false
    @State private var isCategoryLoading = false
    @State private var filteredSurveys: [SurveyEntry] = []

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                Group {
                    if preloadedSurveys.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "chart.bar.xaxis")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)

                            Text("No survey responses found")
                                .font(.title2)
                                .foregroundColor(.gray)
                        }
                    } else {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 20) {
                                // Chart title
                                if !preloadedQuestionKey.isEmpty {
                                    Text(preloadedQuestionKey)
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .padding(.horizontal)
                                        .padding(.top, 8)
                                }

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
                                        "Total Responses: \(preloadedSurveys.count)"
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
            .navigationTitle("\(topic) - \(date)")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showCategoryDetails) {
                if let category = selectedCategory {
                    SurveyCategoryDetailsView(
                        category: category,
                        surveys: filteredSurveys,
                        questionKey: preloadedQuestionKey,
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
        filteredSurveys = []

        // Use a small delay to show the loading indicator
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Filter surveys by the selected category
            filteredSurveys = preloadedSurveys.filter {
                if let response = $0.responsePair {
                    if isPercentageData {
                        let valueStr = response.value.replacingOccurrences(
                            of: "%",
                            with: ""
                        )
                        if let value = Int(valueStr) {
                            let responseCategory = getPercentageCategory(value)
                            return responseCategory == category
                        }
                    } else {
                        return response.value.lowercased()
                            == category.lowercased()
                    }
                }
                return false
            }

            isCategoryLoading = false
            showCategoryDetails = true
        }
    }

    private func getPercentageCategory(_ value: Int) -> String {
        switch value {
        case 0...20: return "0-20%"
        case 21...40: return "21-40%"
        case 41...60: return "41-60%"
        case 61...80: return "61-80%"
        default: return "81-100%"
        }
    }

    private func barColor(for category: String) -> Color {
        if isPercentageData {
            // For percentage responses
            switch category {
            case "0-20%": return .red
            case "21-40%": return .orange
            case "41-60%": return .yellow
            case "61-80%": return .blue
            case "81-100%": return .green
            default: return .gray
            }
        } else {
            // For difficulty responses
            switch category.lowercased() {
            case "very easy": return .green
            case "easy": return .mint
            case "medium": return .blue
            case "hard": return .orange
            case "very hard": return .red
            default: return .gray
            }
        }
    }
}

struct SimpleSurveyCommandView: View {
    @Bindable var bot: Bot

    @State private var message: String = ""
    @State private var selectedButtonType: String = ""
    @State private var mainTopic: String = ""
    @State private var selectedChannelId: String?
    @State private var channels: [Channel] = []
    @State private var isLoading = false
    @State private var isCreating = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    @State private var showFeedback = false
    @State private var surveyDuration: Double = 60  // Default 60 seconds
    @State private var surveyFiles: [SurveyFile] = []
    @State private var isFilesLoading = false
    @State private var selectedFile: SurveyFile?
    @State private var showDetails = false
    @State private var surveyCounts: [String: Int] = [:]
    @State private var loadingFiles: Set<String> = []

    // Data for details view
    @State private var loadedSurveys: [SurveyEntry] = []
    @State private var loadedChartData: [ChartData] = []
    @State private var loadedQuestionKey: String = ""
    @State private var isPercentageData: Bool = false
    @State private var isDataLoading = false

    private let buttonTypes = ["Difficulty", "Score"]

    // Format duration as MM:ss
    private var formattedDuration: String {
        let minutes = Int(surveyDuration) / 60
        let seconds = Int(surveyDuration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    // Get only simple survey files (SS_ prefix)
    private var simpleSurveyFiles: [SurveyFile] {
        surveyFiles.filter { $0.name.hasPrefix("SS_") }
    }

    // Format date from filename
    private func formatDate(from filename: String) -> String? {
        // Extract date parts from filename (e.g., SS_OP OPA_2025-04-28_15-00.csv)
        let components = filename.split(separator: "_")
        guard components.count >= 4 else { return nil }

        let dateStr =
            "\(components[2])_\(components[3].replacingOccurrences(of: ".csv", with: ""))"

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm"

        guard let date = dateFormatter.date(from: dateStr) else { return nil }

        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "EEE d MMMM, HH:mm"

        return outputFormatter.string(from: date)
    }

    // Get display name without SS_ prefix
    private func displayName(for filename: String) -> String {
        guard filename.hasPrefix("SS_") else { return filename }
        return String(filename.dropFirst(3))
    }

    // Extract topic name from filename
    private func extractTopic(from filename: String) -> String {
        // Remove SS_ prefix first
        let nameWithoutPrefix = displayName(for: filename)

        // Split by underscore and get the first part (before the date)
        let components = nameWithoutPrefix.split(separator: "_")
        guard components.count >= 1 else { return nameWithoutPrefix }

        return String(components[0])
    }

    var body: some View {
        Form {
            if !isLoading {
                Section(header: RequiredSectionHeader(text: "Message")) {
                    TextEditor(text: $message)
                        .frame(minHeight: 100)
                        .autocapitalization(.none)
                }
                .listRowInsets(
                    EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16)
                )

                Section(header: RequiredSectionHeader(text: "Button Type")) {
                    Picker("Button", selection: $selectedButtonType) {
                        Text("Select Button type").tag("")
                        ForEach(buttonTypes, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }
                    .pickerStyle(.menu)

                    if selectedButtonType == "Difficulty" {
                        ButtonTypePreview(
                            title: "Difficulty",
                            buttons: [
                                "Very Easy", "Easy", "Medium", "Hard",
                                "Very Hard",
                            ],
                            colors: [.green, .mint, .blue, .orange, .red]
                        )
                    } else if selectedButtonType == "Score" {
                        ButtonTypePreview(
                            title: "Score",
                            buttons: ["20", "40", "60", "80", "100"],
                            colors: [.red, .orange, .yellow, .blue, .green]
                        )
                    }
                }

                Section(header: RequiredSectionHeader(text: "Main Topic")) {
                    TextField("Enter the main topic", text: $mainTopic)
                        .autocapitalization(.none)
                }
                .listRowInsets(
                    EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16)
                )

                Section(header: RequiredSectionHeader(text: "Channel")) {
                    Picker("Channel", selection: $selectedChannelId) {
                        Text("Select a channel").tag(nil as String?)
                        ForEach(channels.filter { $0.type == "text" }) {
                            channel in
                            Text(channel.name).tag(channel.id as String?)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section(header: Text("Survey Duration")) {
                    HStack {
                        Text("Duration: \(formattedDuration)")
                        Spacer()
                        Text("\(Int(surveyDuration)) sec")
                            .foregroundColor(.gray)
                            .font(.caption)
                    }

                    Slider(
                        value: $surveyDuration,
                        in: 30...300,
                        step: 5
                    ) {
                        Text("Survey Duration")
                    } minimumValueLabel: {
                        Text("30s")
                            .font(.caption)
                    } maximumValueLabel: {
                        Text("5m")
                            .font(.caption)
                    }

                    Button(isCreating ? "Creating..." : "Create Survey") {
                        createSurvey()
                    }
                    .disabled(
                        isCreating || message.isEmpty
                            || selectedButtonType.isEmpty || mainTopic.isEmpty
                            || selectedChannelId == nil
                    )
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 5)
                }
                .listRowInsets(
                    EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
                )

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

                Section(header: Text("Survey History")) {
                    if isFilesLoading {
                        HStack {
                            Spacer()
                            ProgressView()
                                .padding()
                            Spacer()
                        }
                    } else if simpleSurveyFiles.isEmpty {
                        Text("No simple survey files available")
                            .foregroundColor(.gray)
                            .font(.caption)
                    } else {
                        List {
                            ForEach(simpleSurveyFiles) { file in
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(extractTopic(from: file.name))
                                            .font(.headline)

                                        Spacer()

                                        if loadingFiles.contains(file.name) {
                                            ProgressView()
                                                .scaleEffect(0.8)
                                        } else {
                                            Text(
                                                "\(surveyCounts[file.name] ?? 0) participants"
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
                                .frame(maxWidth: .infinity, alignment: .leading)
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
                                    loadSurveyDetails(for: file)
                                }
                                .onAppear {
                                    loadSurveyCount(for: file.name)
                                }
                                .listRowSeparator(.hidden)
                            }
                        }
                        .listStyle(PlainListStyle())
                        .frame(maxWidth: .infinity, minHeight: 500)
                        .frame(
                            maxWidth: .infinity,
                            maxHeight: .infinity,
                            alignment: .leading
                        )
                        .background(Color(.white))
                        .cornerRadius(10)
                        .padding(.vertical, 8)

                        if isDataLoading {
                            HStack {
                                Spacer()
                                VStack {
                                    ProgressView()
                                    Text("Loading survey data...")
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
                    EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
                )

            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Simple Survey")
        .sheet(isPresented: $showDetails) {
            if let file = selectedFile,
                let formattedDate = formatDate(from: file.name)
            {
                SurveyDetailsView(
                    fileName: file.name,
                    topic: extractTopic(from: file.name),
                    date: formattedDate,
                    preloadedSurveys: loadedSurveys,
                    preloadedChartData: loadedChartData,
                    preloadedQuestionKey: loadedQuestionKey,
                    isPercentageData: isPercentageData
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .interactiveDismissDisabled(false)
            }
        }
        .onAppear {
            fetchChannels()
            loadSurveyFiles()
        }
        .refreshable {
            fetchChannels()
            loadSurveyFiles()
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

    private func createSurvey() {
        guard
            !message.isEmpty,
            !selectedButtonType.isEmpty,
            !mainTopic.isEmpty,
            let channelId = selectedChannelId
        else {
            return
        }

        isCreating = true
        errorMessage = nil
        successMessage = nil
        showFeedback = false

        Task {
            let result = await bot.apiClient.createSimpleSurvey(
                message: message,
                mainTopic: mainTopic,
                channelId: channelId,
                buttonType: selectedButtonType,
                duration: Int(surveyDuration)
            )

            DispatchQueue.main.async {
                isCreating = false
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

    private func loadSurveyFiles() {
        isFilesLoading = true
        errorMessage = nil

        Task {
            let result = await bot.apiClient.fetchSurveyFiles()

            DispatchQueue.main.async {
                isFilesLoading = false

                switch result {
                case .success(let files):
                    // Sort files by creation date in descending order (newest first)
                    self.surveyFiles = files.sorted {
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
                        "Failed to load survey files: \(message)"
                    self.showFeedback = true
                }
            }
        }
    }

    private func loadSurveyDetails(for file: SurveyFile) {
        isDataLoading = true
        selectedFile = file
        loadedSurveys = []
        loadedChartData = []
        loadedQuestionKey = ""

        Task {
            let result = await bot.apiClient.fetchSurveyContent(
                fileName: file.name
            )

            DispatchQueue.main.async {
                isDataLoading = false

                switch result {
                case .success(let content):
                    self.loadedSurveys = content

                    // Get the question key from the first entry
                    if let firstEntry = content.first,
                        let responsePair = firstEntry.responsePair
                    {
                        self.loadedQuestionKey = responsePair.key

                        // Determine if we're dealing with percentage data
                        self.isPercentageData = responsePair.value.hasSuffix(
                            "%"
                        )

                        // Prepare chart data
                        self.loadedChartData = prepareChartData(from: content)

                        // Now that we have the data, show the details view
                        self.showDetails = true
                    } else {
                        self.loadedSurveys = []
                        self.loadedChartData = []
                        self.loadedQuestionKey = ""
                        self.showDetails = true
                    }

                case .failure(let message):
                    self.errorMessage = "Failed to load survey data: \(message)"
                    self.showFeedback = true
                }
            }
        }
    }

    private func prepareChartData(from surveys: [SurveyEntry]) -> [ChartData] {
        var categoryCounts: [String: Int] = [:]

        // Process all responses
        for survey in surveys {
            if let response = survey.responsePair {
                if isPercentageData {
                    // For percentage responses
                    let valueStr = response.value.replacingOccurrences(
                        of: "%",
                        with: ""
                    )
                    if let value = Int(valueStr) {
                        let category = getPercentageCategory(value)
                        categoryCounts[category, default: 0] += 1
                    }
                } else {
                    // For difficulty responses
                    categoryCounts[response.value, default: 0] += 1
                }
            }
        }

        // Convert dictionary to array and sort properly
        if isPercentageData {
            let percentageOrder = [
                "0-20%", "21-40%", "41-60%", "61-80%", "81-100%",
            ]
            return percentageOrder.map { category in
                ChartData(
                    category: category,
                    count: categoryCounts[category, default: 0]
                )
            }
        } else {
            let difficultyOrder = [
                "Very Easy", "Easy", "Medium", "Hard", "Very Hard",
            ]
            return difficultyOrder.map { category in
                // Find case-insensitive match
                let count =
                    categoryCounts.first {
                        $0.key.lowercased() == category.lowercased()
                    }?.value ?? 0
                return ChartData(category: category, count: count)
            }
        }
    }

    private func getPercentageCategory(_ value: Int) -> String {
        switch value {
        case 0...20: return "0-20%"
        case 21...40: return "21-40%"
        case 41...60: return "41-60%"
        case 61...80: return "61-80%"
        default: return "81-100%"
        }
    }

    private func loadSurveyCount(for fileName: String) {
        guard !loadingFiles.contains(fileName) else { return }

        loadingFiles.insert(fileName)

        Task {
            let result = await bot.apiClient.fetchSurveyContent(
                fileName: fileName
            )

            DispatchQueue.main.async {
                loadingFiles.remove(fileName)

                switch result {
                case .success(let content):
                    surveyCounts[fileName] = content.count
                case .failure(let message):
                    print(
                        "Failed to load survey count for \(fileName): \(message)"
                    )
                    surveyCounts[fileName] = 0
                }
            }
        }
    }
}

// Button type preview component
struct ButtonTypePreview: View {
    let title: String
    let buttons: [String]
    let colors: [Color]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Preview: \(title) Buttons")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.top, 4)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(0..<buttons.count, id: \.self) { index in
                        Text(buttons[index])
                            .font(.caption)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .padding(
                                .horizontal,
                                buttons[index].count > 7 ? 6 : 10
                            )
                            .padding(.vertical, 6)
                            .background(colors[index])
                            .foregroundColor(.white)
                            .cornerRadius(5)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }
}

#Preview {
    SimpleSurveyCommandView(bot: SampleData.shared.bot)
        .modelContainer(SampleData.shared.modelContainer)
}
