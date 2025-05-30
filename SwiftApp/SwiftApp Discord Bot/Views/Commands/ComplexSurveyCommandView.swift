import Charts
import SwiftData
import SwiftUI

// Complex Survey Details View
struct ComplexSurveyDetailsView: View {
    let fileName: String
    let topic: String
    let date: String
    let preloadedSurveys: [SurveyEntry]

    @State private var selectedKey: String? = nil
    @State private var showResponseDetails = false
    @State private var isLoading = false
    @State private var filteredSurveys: [SurveyEntry] = []

    @Environment(\.dismiss) private var dismiss

    // Get unique keys from all survey entries
    private var uniqueKeys: [String] {
        var keys = Set<String>()
        for survey in preloadedSurveys {
            for pair in survey.responsePairs {
                keys.insert(pair.key)
            }
        }
        return Array(keys).sorted()
    }

    var body: some View {
        NavigationStack {
            Group {
                if preloadedSurveys.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "chart.bar.xaxis")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)

                        Text("No survey responses found")
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(uniqueKeys, id: \.self) { key in
                            KeyRow(
                                key: key,
                                isLoading: isLoading && selectedKey == key
                            )
                            .onTapGesture {
                                prepareAndShowDetails(for: key)
                            }
                        }
                    }
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: .infinity,
                        alignment: .leading
                    )
                    .listStyle(PlainListStyle())
                    .background(Color(.white))
                    .cornerRadius(10)
                    .padding(.vertical, 8)
                    .disabled(isLoading)
                }
            }
            .navigationTitle("\(topic) - \(date)")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showResponseDetails) {
            if let key = selectedKey {
                SurveyResponseDetailsView(key: key, surveys: filteredSurveys)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
        }
    }

    private func prepareAndShowDetails(for key: String) {
        // Set loading state and selected key
        isLoading = true
        selectedKey = key
        filteredSurveys = []

        // Process data with a slight delay to show loading indicator
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Filter surveys to only include entries that have the selected key
            filteredSurveys = preloadedSurveys.filter { survey in
                return survey.responsePairs.contains { $0.key == key }
            }

            // Show details only after data is prepared
            isLoading = false
            showResponseDetails = true
        }
    }
}

// Row for question keys
struct KeyRow: View {
    let key: String
    let isLoading: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(key)
                    .font(.headline)

                Spacer()

                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(Color(.systemGray6))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
            .contentShape(Rectangle())
        }
        .padding(.vertical, 4)
    }
}

// Chart data model
struct ComplexChartData: Identifiable {
    let id = UUID()
    let category: String
    let count: Int
}

// Survey Response Details View for people in category
struct SurveyCategoryPeopleView: View {
    let key: String
    let category: String
    let surveys: [SurveyEntry]
    let color: Color

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
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
            .navigationTitle("\(key): \(category)")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// Survey Response Details View
struct SurveyResponseDetailsView: View {
    let key: String
    let surveys: [SurveyEntry]

    @State private var chartData: [ComplexChartData] = []
    @State private var isPercentageData: Bool = false
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
                    if surveys.isEmpty {
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
                                Text(key)
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
                                        ForEach(chartData) { item in
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

                                    ForEach(chartData) { item in
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
                                    Text("Total Responses: \(surveys.count)")
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
            .navigationTitle(key)
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                prepareChartData()
            }
            .sheet(isPresented: $showCategoryDetails) {
                if let category = selectedCategory {
                    SurveyCategoryPeopleView(
                        key: key,
                        category: category,
                        surveys: filteredSurveys,
                        color: barColor(for: category)
                    )
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                }
            }
        }
    }

    private func prepareChartData() {
        // Analyze all responses to determine data type (percentage or difficulty)
        var isPercentage = false
        var responseCounts: [String: Int] = [:]

        for survey in surveys {
            if let value = getResponseValue(for: key, from: survey) {
                if value.hasSuffix("%") {
                    isPercentage = true

                    // For percentage, categorize into ranges
                    let valueStr = value.replacingOccurrences(of: "%", with: "")
                    if let numValue = Int(valueStr) {
                        let category = getPercentageCategory(numValue)
                        responseCounts[category, default: 0] += 1
                    }
                } else {
                    // For difficulty values
                    responseCounts[value, default: 0] += 1
                }
            }
        }

        self.isPercentageData = isPercentage

        // Convert to chart data in the right order
        if isPercentage {
            let percentageOrder = [
                "0-20%", "21-40%", "41-60%", "61-80%", "81-100%",
            ]
            chartData = percentageOrder.map { category in
                ComplexChartData(
                    category: category,
                    count: responseCounts[category, default: 0]
                )
            }
        } else {
            // Assume difficulty values if not percentage
            let difficultyOrder = [
                "Very Easy", "Easy", "Medium", "Hard", "Very Hard",
            ]

            // Check if we have any of these values
            let hasStandardDifficulty = difficultyOrder.contains {
                responseCounts[$0, default: 0] > 0
            }

            if hasStandardDifficulty {
                chartData = difficultyOrder.map { category in
                    // Find case-insensitive match
                    let count =
                        responseCounts.first {
                            $0.key.lowercased() == category.lowercased()
                        }?.value ?? 0
                    return ComplexChartData(category: category, count: count)
                }
            } else {
                // Just use the keys from responseCounts sorted alphabetically
                chartData = responseCounts.map {
                    ComplexChartData(category: $0.key, count: $0.value)
                }.sorted { $0.category < $1.category }
            }
        }
    }

    private func getResponseValue(for key: String, from survey: SurveyEntry)
        -> String?
    {
        return survey.responsePairs.first { $0.key == key }?.value
    }

    private func loadCategoryDetails(for category: String) {
        isCategoryLoading = true
        selectedCategory = category
        filteredSurveys = []

        // Use a small delay to show the loading indicator
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Filter surveys by the selected category
            filteredSurveys = surveys.filter { survey in
                if let value = getResponseValue(for: key, from: survey) {
                    if isPercentageData {
                        let valueStr = value.replacingOccurrences(
                            of: "%",
                            with: ""
                        )
                        if let numValue = Int(valueStr) {
                            let responseCategory = getPercentageCategory(
                                numValue
                            )
                            return responseCategory == category
                        }
                    } else {
                        return value.lowercased() == category.lowercased()
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

struct ComplexSurveyCommandView: View {
    @Bindable var bot: Bot

    @State private var message: String = ""
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
    @State private var surveyCounts: [String: Int] = [:]
    @State private var loadingFiles: Set<String> = []

    // Questions configuration
    @State private var numberOfQuestions = 1
    @State private var questions: [Question] = [Question()]

    // Available number of questions
    let questionOptions = Array(1...10)

    @State private var showValidationAlert = false
    @State private var validationMessage = ""

    @State private var selectedFile: SurveyFile?
    @State private var showDetails = false
    @State private var isDetailDataLoading = false
    @State private var loadedSurveys: [SurveyEntry] = []

    // Format duration as MM:ss
    private var formattedDuration: String {
        let minutes = Int(surveyDuration) / 60
        let seconds = Int(surveyDuration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    // Get only complex survey files (CS_ prefix)
    private var complexSurveyFiles: [SurveyFile] {
        surveyFiles.filter { $0.name.hasPrefix("CS_") }
    }

    // Format date from filename
    private func formatDate(from filename: String) -> String? {
        // Extract date parts from filename (e.g., CS_Tutorial 1_2025-04-29_13-35.csv)
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

    // Get display name without CS_ prefix
    private func displayName(for filename: String) -> String {
        guard filename.hasPrefix("CS_") else { return filename }
        return String(filename.dropFirst(3))
    }

    // Extract topic name from filename
    private func extractTopic(from filename: String) -> String {
        // Remove CS_ prefix first
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

                Section(header: RequiredSectionHeader(text: "Main Topic")) {
                    TextField("Enter the main topic", text: $mainTopic)
                        .autocapitalization(.none)
                }

                Section(header: RequiredSectionHeader(text: "Channel")) {
                    Picker("Select Channel", selection: $selectedChannelId) {
                        Text("Select a channel").tag(nil as String?)
                        ForEach(channels.filter { $0.type == "text" }) {
                            channel in
                            Text(channel.name).tag(channel.id as String?)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section(header: RequiredSectionHeader(text: "Questions")) {
                    Picker("Number of Questions", selection: $numberOfQuestions)
                    {
                        ForEach(questionOptions, id: \.self) { number in
                            Text("\(number)").tag(number)
                        }
                    }
                    .onChange(of: numberOfQuestions) { oldValue, newValue in
                        updateQuestions(count: newValue)
                    }

                    ForEach(0..<questions.count, id: \.self) { index in
                        VStack(alignment: .leading) {
                            Text("Question \(index + 1)")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            HStack {
                                TextField(
                                    "Enter question",
                                    text: $questions[index].text
                                )
                                .onChange(of: questions[index].text) {
                                    oldValue,
                                    newValue in
                                    if newValue.count > Question.maxCharacters {
                                        questions[index].text = String(
                                            newValue.prefix(
                                                Question.maxCharacters
                                            )
                                        )
                                    }
                                }

                                Picker(
                                    "",
                                    selection: $questions[index].buttonType
                                ) {
                                    Text("Select button").tag("")
                                    Text("Score").tag("Score")
                                    Text("Difficulty").tag("Difficulty")
                                }
                                .pickerStyle(.menu)
                                .frame(width: 140)
                            }

                            HStack {
                                Text(
                                    "\(questions[index].characterCount)/\(Question.maxCharacters) characters"
                                )
                                .font(.caption2)
                                .foregroundColor(
                                    questions[index].characterCount
                                        > Question.maxCharacters
                                        ? .red : .secondary
                                )
                                Spacer()
                            }
                        }
                        .padding(.vertical, 4)
                    }
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
                        if validateQuestions() {
                            createSurvey()
                        } else {
                            showValidationAlert = true
                        }
                    }
                    .disabled(
                        isCreating || message.isEmpty || mainTopic.isEmpty
                            || selectedChannelId == nil
                    )
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 5)
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

            Section(header: Text("Survey History")) {
                if isFilesLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                            .padding()
                        Spacer()
                    }
                } else if complexSurveyFiles.isEmpty {
                    Text("No complex survey files available")
                        .foregroundColor(.gray)
                        .font(.caption)
                } else {
                    List {
                        ForEach(complexSurveyFiles) { file in
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
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Complex Survey")
        .sheet(isPresented: $showDetails) {
            if let file = selectedFile,
                let formattedDate = formatDate(from: file.name)
            {
                ComplexSurveyDetailsView(
                    fileName: file.name,
                    topic: extractTopic(from: file.name),
                    date: formattedDate,
                    preloadedSurveys: loadedSurveys
                )
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
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
        .alert("Incomplete Questions", isPresented: $showValidationAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(validationMessage)
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

    private func updateQuestions(count: Int) {
        // Keep existing questions up to the new count
        if count <= questions.count {
            questions = Array(questions.prefix(count))
        } else {
            // Add new questions up to the requested count
            let additionalQuestions = (questions.count..<count).map { _ in
                Question()
            }
            questions.append(contentsOf: additionalQuestions)
        }
    }

    private func validateQuestions() -> Bool {
        var incompleteQuestions: [String] = []

        for (index, question) in questions.enumerated() {
            let questionNumber = index + 1

            if question.text.isEmpty {
                incompleteQuestions.append(
                    "Question \(questionNumber): Missing text"
                )
            }

            if question.buttonType.isEmpty {
                incompleteQuestions.append(
                    "Question \(questionNumber): Missing button type"
                )
            }
        }

        if incompleteQuestions.isEmpty {
            return true
        } else {
            validationMessage =
                "Please complete the following:\n"
                + incompleteQuestions.joined(separator: "\n")
            return false
        }
    }

    private func createSurvey() {
        guard
            !message.isEmpty,
            !mainTopic.isEmpty,
            let channelId = selectedChannelId,
            !questions.isEmpty,
            questions.allSatisfy({ !$0.text.isEmpty && !$0.buttonType.isEmpty })
        else {
            return
        }

        isCreating = true
        errorMessage = nil
        successMessage = nil
        showFeedback = false

        // Convert questions to the format expected by the API
        let questionData = questions.map {
            (text: $0.text, buttonType: $0.buttonType)
        }

        Task {
            // Construct the URL with parameters including duration
            var urlComponents = URLComponents(
                string: "\(bot.apiClient.serverIP)/api/create-complex-survey"
            )
            var queryItems = [
                URLQueryItem(name: "api_key", value: bot.apiClient.apiKey),
                URLQueryItem(name: "message", value: message),
                URLQueryItem(name: "main_topic", value: mainTopic),
                URLQueryItem(name: "channel_id", value: channelId),
                URLQueryItem(name: "duration", value: "\(Int(surveyDuration))"),
            ]

            // Add questions and button types
            for (index, question) in questions.enumerated() {
                let questionNumber = index + 1
                queryItems.append(
                    URLQueryItem(
                        name: "question_\(questionNumber)",
                        value: question.text
                    )
                )
                queryItems.append(
                    URLQueryItem(
                        name: "button_\(questionNumber)",
                        value: question.buttonType
                    )
                )
            }

            let result = await bot.apiClient.createComplexSurvey(
                message: message,
                mainTopic: mainTopic,
                channelId: channelId,
                questions: questionData,
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
        isDetailDataLoading = true
        selectedFile = file
        loadedSurveys = []

        Task {
            let result = await bot.apiClient.fetchSurveyContent(
                fileName: file.name
            )

            DispatchQueue.main.async {
                isDetailDataLoading = false

                switch result {
                case .success(let content):
                    self.loadedSurveys = content
                    self.showDetails = true

                case .failure(let message):
                    self.errorMessage =
                        "Failed to load survey details: \(message)"
                    self.showFeedback = true
                }
            }
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

// Model for survey questions
struct Question {
    var text: String = ""
    var buttonType: String = ""
    var characterCount: Int { text.count }
    static let maxCharacters = 50
}

#Preview {
    ComplexSurveyCommandView(bot: SampleData.shared.bot)
        .modelContainer(SampleData.shared.modelContainer)
}
