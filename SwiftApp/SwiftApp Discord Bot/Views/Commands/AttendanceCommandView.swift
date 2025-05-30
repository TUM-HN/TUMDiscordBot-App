import SwiftData
import SwiftUI

// Attendance Details View
struct AttendanceDetailsView: View {
    let fileName: String
    let groupName: String
    let date: String
    let preloadedAttendees: [AttendanceEntry]

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if preloadedAttendees.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "person.2.slash")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)

                        Text("No attendees found")
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(preloadedAttendees, id: \.Attendance) {
                            attendee in
                            Text(attendee.Attendance)
                                .font(.body)
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("\(groupName) - \(date)")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct AttendanceCommandView: View {
    @Bindable var bot: Bot
    @Environment(\.modelContext) private var context

    @State private var selectedGroupId: String?
    @State private var attendanceStatus: Bool = false  // false = stop, true = start
    @State private var showConfirmation: Bool = false
    @State private var isLoading = false
    @State private var isProcessing = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    @State private var showFeedback = false
    @State private var attendanceFiles: [AttendanceFile] = []
    @State private var isFilesLoading = false
    @State private var attendanceCounts: [String: Int] = [:]
    @State private var loadingFiles: Set<String> = []
    @State private var selectedFile: AttendanceFile?
    @State private var showDetails = false
    @State private var isDetailDataLoading = false
    @State private var loadedAttendees: [AttendanceEntry] = []
    @State private var attendanceCode: String = ""  // New state for attendance code

    // Added state for members
    @State private var members: [Member] = []
    @State private var isLoadingMembers = false
    @State private var selectedMemberId: String?
    @State private var adminMembers: [Member] = []

    // Computed property to get valid groups from the bot model
    private var validGroups: [GroupModel] {
        return bot.groups.filter { $0.isValid }
    }

    // Get the selected group
    private var selectedGroup: GroupModel? {
        guard let selectedGroupId = selectedGroupId else { return nil }
        return validGroups.first { $0.name == selectedGroupId }
    }

    // Check if selected group has active attendance
    private var isAttendanceActive: Bool {
        return selectedGroup?.attendanceActive ?? false
    }

    // Format date from filename
    private func formatDate(from filename: String) -> String? {
        // Extract date parts from filename (e.g., g2_2025-04-28_15-31.csv)
        let components = filename.split(separator: "_")
        guard components.count >= 3 else { return nil }

        let dateStr =
            "\(components[1])_\(components[2].replacingOccurrences(of: ".csv", with: ""))"

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm"

        guard let date = dateFormatter.date(from: dateStr) else { return nil }

        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "EEE d MMMM HH:mm"

        return outputFormatter.string(from: date)
    }

    // Extract group name from filename
    private func extractGroupName(from filename: String) -> String {
        let components = filename.split(separator: "_")
        guard let groupName = components.first else { return filename }
        return groupName.uppercased()
    }

    var body: some View {
        Form {
            if !isLoading {
                Section(header: RequiredSectionHeader(text: "Attendance Setup")) {
                    if validGroups.isEmpty {
                        Text(
                            "No valid groups available. Please add groups in Settings."
                        )
                        .foregroundColor(.red)
                        .font(.caption)
                    } else {
                        Picker("Select Group", selection: $selectedGroupId) {
                            Text("Select a group").tag(nil as String?)
                            ForEach(validGroups, id: \.name) { group in
                                Text(group.name).tag(group.name as String?)
                            }
                        }
                        .pickerStyle(.menu)

                        if isLoadingMembers {
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                            .padding(.vertical, 4)
                        } else if adminMembers.isEmpty {
                            Text(
                                "No admin members found. Please make sure you have members with Admin role."
                            )
                            .font(.caption)
                            .foregroundColor(.red)
                        } else {
                            Picker("Admin", selection: $selectedMemberId) {
                                Text("Select an admin").tag(nil as String?)
                                ForEach(adminMembers, id: \.id) { member in
                                    Text(member.displayName).tag(
                                        member.id as String?
                                    )
                                }
                            }
                            .pickerStyle(.menu)
                        }
                    }
                }

                Section(header: Text("Attendance Status")) {
                    VStack {
                        Picker("Status", selection: $attendanceStatus) {
                            Text("Stop").tag(false)
                            Text("Start").tag(true)
                        }
                        .pickerStyle(.segmented)
                        .disabled(
                            selectedGroupId == nil || isProcessing
                                || selectedMemberId == nil
                        )

                        if selectedGroupId != nil {
                            HStack {
                                Text("Current Status:")
                                Spacer()
                                Text(isAttendanceActive ? "Active" : "Inactive")
                                    .foregroundColor(
                                        isAttendanceActive ? .green : .gray
                                    )
                            }
                        }

                        // New attendance code field
                        HStack {
                            Text("Attendance Code").required()
                            Spacer()
                            TextField("Enter code", text: $attendanceCode)
                                .keyboardType(.numberPad)
                                .disabled(isAttendanceActive)
                                .opacity(isAttendanceActive ? 0.6 : 1.0)
                                .textFieldStyle(.plain)
                                .frame(width: 100)
                                .multilineTextAlignment(.trailing)
                        }
                        .padding(.vertical, 8)
                    }

                    Button(
                        isProcessing
                            ? "Processing..."
                            : (attendanceStatus
                                ? "Start Attendance" : "Stop Attendance")
                    ) {
                        manageAttendance()
                    }
                    .disabled(
                        selectedGroupId == nil || isProcessing
                            || selectedMemberId == nil
                            || (attendanceStatus && isAttendanceActive)
                            || (!attendanceStatus && !isAttendanceActive)
                            || attendanceCode.isEmpty
                    )
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 5)
                }
                .listRowInsets(
                    EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16)
                )

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
                                Image(
                                    systemName: "exclamationmark.triangle.fill"
                                )
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
            }
            Section(header: Text("Attendance History")) {
                if isFilesLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                            .padding()
                        Spacer()
                    }
                } else if attendanceFiles.isEmpty {
                    Text("No attendance files available")
                        .foregroundColor(.gray)
                        .font(.caption)
                } else {
                    List {
                        ForEach(attendanceFiles) { file in
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
                                            "\(attendanceCounts[file.name] ?? 0) attendees"
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
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                loadAttendanceDetails(for: file)
                            }
                            .onAppear {
                                loadAttendanceCount(for: file.name)
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
                }

                if isDetailDataLoading {
                    HStack {
                        Spacer()
                        VStack {
                            ProgressView()
                            Text("Loading attendance data...")
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
        .listStyle(.insetGrouped)
        .navigationTitle("Attendance")
        .sheet(isPresented: $showDetails) {
            if let file = selectedFile,
                let formattedDate = formatDate(from: file.name)
            {
                AttendanceDetailsView(
                    fileName: file.name,
                    groupName: extractGroupName(from: file.name),
                    date: formattedDate,
                    preloadedAttendees: loadedAttendees
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
        }
        .onChange(of: selectedGroupId) { _ in
            attendanceCode = selectedGroup?.attendanceCode ?? ""
            attendanceStatus = selectedGroup?.attendanceActive ?? false
        }
        .onAppear {
            // Initialize the group if there are valid groups available
            if let firstGroup = validGroups.first {
                selectedGroupId = firstGroup.name
                attendanceCode = firstGroup.attendanceCode ?? ""
                attendanceStatus = firstGroup.attendanceActive
            } else {
                errorMessage =
                    "No valid groups available. Please add groups in Settings."
                showFeedback = true
            }

            // Load attendance files
            loadAttendanceFiles()

            // Load Discord members
            loadMembers()
        }
        .refreshable {
            loadAttendanceFiles()
            loadMembers()
        }
    }

    private func manageAttendance() {
        // Remember code before API call
        let currentCode = attendanceCode
        guard let groupId = selectedGroupId, let group = selectedGroup else {
            errorMessage = "Please select a group."
            showFeedback = true
            return
        }

        guard let memberId = selectedMemberId else {
            errorMessage = "Please select an admin member."
            showFeedback = true
            return
        }
        // Validate that code is provided when starting
        guard !attendanceCode.isEmpty else {
            errorMessage = "Please enter an attendance code."
            showFeedback = true
            return
        }

        // Validate that we're not trying to set a state that's already set
        if attendanceStatus == group.attendanceActive {
            errorMessage =
                attendanceStatus
                ? "Attendance is already active for this group."
                : "Attendance is already inactive for this group."
            showFeedback = true
            return
        }

        isProcessing = true
        errorMessage = nil
        successMessage = nil
        showFeedback = false

        Task {
            // Call the API client with the updated parameters
            let result = await bot.apiClient.manageAttendance(
                groupId: groupId,
                targetUserId: memberId,
                status: attendanceStatus,
                code: currentCode
            )

            DispatchQueue.main.async {
                isProcessing = false
                showFeedback = true

                switch result {
                case .success(let message):
                    successMessage = message

                    // Update the group's attendance status and code
                    group.attendanceActive = attendanceStatus
                    group.attendanceCode = attendanceStatus ? currentCode : nil
                    try? context.save()
                    
                    // Clear local code if stopping attendance
                    if !attendanceStatus {
                        attendanceCode = ""
                    }

                case .failure(let message):
                    errorMessage = message
                }
            }
        }
    }

    private func loadMembers() {
        isLoadingMembers = true
        adminMembers = []

        Task {
            let result = await bot.apiClient.fetchMembers()

            DispatchQueue.main.async {
                isLoadingMembers = false

                switch result {
                case .success(let fetchedMembers):
                    self.members = fetchedMembers

                    // Filter members to those with Admin role
                    loadAdminMembers()

                case .failure(let message):
                    errorMessage = "Failed to load members: \(message)"
                    showFeedback = true
                }
            }
        }
    }

    private func loadAdminMembers() {
        Task {
            // First fetch roles to find the Admin role ID
            let rolesResult = await bot.apiClient.fetchRoles()

            DispatchQueue.main.async {
                switch rolesResult {
                case .success(let roles):
                    // Find the Admin role ID
                    if let adminRole = roles.first(where: { $0.name == "Admin" }
                    ) {
                        // Filter members to those that have the Admin role
                        self.adminMembers = self.members.filter { member in
                            return member.roles.contains(adminRole.id)
                        }

                        if !self.adminMembers.isEmpty
                            && self.selectedMemberId == nil
                        {
                            // Set the first admin member as selected by default
                            self.selectedMemberId = self.adminMembers.first?.id
                        }
                    } else {
                        self.errorMessage = "No Admin role found on the server."
                        self.showFeedback = true
                    }

                case .failure(let message):
                    self.errorMessage = "Failed to load roles: \(message)"
                    self.showFeedback = true
                }
            }
        }
    }

    private func loadAttendanceFiles() {
        isFilesLoading = true
        errorMessage = nil

        Task {
            let result = await bot.apiClient.fetchAttendanceFiles()

            DispatchQueue.main.async {
                isFilesLoading = false

                switch result {
                case .success(let files):
                    // Sort files by creation date in descending order (newest first)
                    self.attendanceFiles = files.sorted {
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
                        "Failed to load attendance files: \(message)"
                    self.showFeedback = true
                }
            }
        }
    }

    private func loadAttendanceCount(for fileName: String) {
        guard !loadingFiles.contains(fileName) else { return }

        loadingFiles.insert(fileName)

        Task {
            let result = await bot.apiClient.fetchAttendanceContent(
                fileName: fileName
            )

            DispatchQueue.main.async {
                loadingFiles.remove(fileName)

                switch result {
                case .success(let content):
                    attendanceCounts[fileName] = content.count
                case .failure(let message):
                    print(
                        "Failed to load attendance count for \(fileName): \(message)"
                    )
                    attendanceCounts[fileName] = 0
                }
            }
        }
    }

    private func loadAttendanceDetails(for file: AttendanceFile) {
        isDetailDataLoading = true
        selectedFile = file
        loadedAttendees = []

        Task {
            let result = await bot.apiClient.fetchAttendanceContent(
                fileName: file.name
            )

            DispatchQueue.main.async {
                isDetailDataLoading = false

                switch result {
                case .success(let content):
                    self.loadedAttendees = content
                    self.showDetails = true

                case .failure(let message):
                    self.errorMessage =
                        "Failed to load attendance details: \(message)"
                    self.showFeedback = true
                }
            }
        }
    }
}

#Preview {
    AttendanceCommandView(bot: SampleData.shared.bot)
        .modelContainer(SampleData.shared.modelContainer)
}
