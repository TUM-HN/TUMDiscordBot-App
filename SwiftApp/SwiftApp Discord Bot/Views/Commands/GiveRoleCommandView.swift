import SwiftData
import SwiftUI

struct GiveRoleCommandView: View {
    @Bindable var bot: Bot

    @State private var selectedMemberId: String?
    @State private var selectedRoleId: String?
    @State private var members: [Member] = []
    @State private var roles: [Role] = []
    @State private var isLoading = false
    @State private var isAssigning = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    @State private var showFeedback = false

    var body: some View {
        Form {
            Section(header: Text("Give Role Command")) {
                if isLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                            .padding()
                        Spacer()
                    }
                } else {
                    Text("Assign a role to a Discord member")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    // Member selection
                    RequiredPicker(title: "Member", selection: $selectedMemberId) {
                        Text("Select a member").tag(nil as String?)
                        ForEach(members) { member in
                            Text("\(member.displayName) (\(member.name))").tag(
                                member.id as String?
                            )
                        }
                    }
                    .pickerStyle(MenuPickerStyle())

                    // Role selection
                    RequiredPicker(title: "Role", selection: $selectedRoleId) {
                        Text("Select a role").tag(nil as String?)
                        ForEach(roles) { role in
                            HStack {
                                Circle()
                                    .frame(width: 12, height: 12)
                                Text(role.name)
                            }
                            .tag(role.id as String?)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())

                    // Send button
                    Button(isAssigning ? "Assigning..." : "Assign Role") {
                        assignRole()
                    }
                    .disabled(
                        selectedMemberId == nil || selectedRoleId == nil
                            || isAssigning
                    )
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
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
        .navigationTitle("Give Role Command")
        .onAppear {
            fetchData()
        }
        .refreshable {
            fetchData()
        }
    }

    private func fetchData() {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        showFeedback = false

        Task {
            // Fetch members
            let membersResult = await bot.apiClient.fetchMembers()

            // Fetch roles
            let rolesResult = await bot.apiClient.fetchRoles()

            DispatchQueue.main.async {
                isLoading = false

                // Process members result
                switch membersResult {
                case .success(let fetchedMembers):
                    self.members = fetchedMembers.sorted {
                        $0.displayName < $1.displayName
                    }
                case .failure(let error):
                    self.errorMessage = "Failed to load members: \(error)"
                    self.showFeedback = true
                }

                // Process roles result
                switch rolesResult {
                case .success(let fetchedRoles):
                    self.roles = fetchedRoles.sorted {
                        $0.position < $1.position
                    }
                case .failure(let error):
                    if self.errorMessage != nil {
                        self.errorMessage =
                            "\(self.errorMessage!)\nFailed to load roles: \(error)"
                    } else {
                        self.errorMessage = "Failed to load roles: \(error)"
                    }
                    self.showFeedback = true
                }
            }
        }
    }

    private func assignRole() {
        guard let memberId = selectedMemberId, let roleId = selectedRoleId
        else { return }

        isAssigning = true
        errorMessage = nil
        successMessage = nil
        showFeedback = false

        Task {
            let result = await bot.apiClient.giveMemberRole(
                userId: memberId,
                roleId: roleId
            )

            DispatchQueue.main.async {
                isAssigning = false
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
    GiveRoleCommandView(bot: SampleData.shared.bot)
        .modelContainer(SampleData.shared.modelContainer)
}

// Add this extension at the end of the file to convert hex color strings to Color
extension Color {
    init?(hex: String) {
        // Handle default Discord color for roles (0)
        if hex == "0" || hex.isEmpty {
            self = .gray
            return
        }

        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0

        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else {
            return nil
        }

        self.init(
            .sRGB,
            red: Double((rgb & 0xFF0000) >> 16) / 255.0,
            green: Double((rgb & 0x00FF00) >> 8) / 255.0,
            blue: Double(rgb & 0x0000FF) / 255.0,
            opacity: 1.0
        )
    }
}
