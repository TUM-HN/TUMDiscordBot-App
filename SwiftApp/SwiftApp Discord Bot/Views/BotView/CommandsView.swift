import SwiftData
import SwiftUI

struct CommandsView: View {
    @Bindable var bot: Bot
    @State private var showPingResult = false
    @State private var pingLatency: String?
    @State private var pingMessage: String?
    @State private var pingError: String?
    @State private var isPinging = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            CommandSection(title: "Simple Commands") {
                // Ping Command
                CommandButton(
                    title: "Ping",
                    systemImage: "arrow.2.circlepath",
                    description: "Check bot response time",
                    isDisabled: !bot.isActive
                ) {
                    pingBot()
                }
            }

            CommandSection(title: "Member Commands") {
                NavigationLink(destination: HelloCommandView(bot: bot)) {
                    CommandRow(
                        title: "Send Message",
                        description: "Send a personalized greeting",
                        systemImage: "message"
                    )
                }

                NavigationLink(destination: GiveRoleCommandView(bot: bot)) {
                    CommandRow(
                        title: "Give Role",
                        description: "Assign a role to a member",
                        systemImage: "person.badge.plus"
                    )
                }
            }

            CommandSection(title: "Channel Commands") {
                NavigationLink(destination: ClearCommandView(bot: bot)) {
                    CommandRow(
                        title: "Clear Messages",
                        description: "Delete messages from a channel",
                        systemImage: "trash"
                    )
                }
            }

            CommandSection(title: "Group Commands") {
                NavigationLink(destination: AttendanceCommandView(bot: bot)) {
                    CommandRow(
                        title: "Attendance",
                        description: "Track attendance in a channel",
                        systemImage: "checklist"
                    )
                }
                NavigationLink(destination: TutorFeedbackCommandView(bot: bot))
                {
                    CommandRow(
                        title: "Tutor Feedback",
                        description: "Get feedback on a session",
                        systemImage: "star"
                    )
                }
            }

            CommandSection(title: "Survey Commands") {
                NavigationLink(destination: SimpleSurveyCommandView(bot: bot)) {
                    CommandRow(
                        title: "Simple Survey",
                        description: "Create a simple survey",
                        systemImage: "list.bullet.clipboard"
                    )
                }
                NavigationLink(destination: ComplexSurveyCommandView(bot: bot))
                {
                    CommandRow(
                        title: "Complex Survey",
                        description: "Create a multi-question survey",
                        systemImage: "doc.text.magnifyingglass"
                    )
                }

            }
        }
        .background(Color.tumGray8.opacity(0.5))
        .cornerRadius(15)
        .padding(.bottom)
        .alert(isPresented: $showPingResult) {
            if let error = pingError {
                return Alert(
                    title: Text("Ping Failed"),
                    message: Text(error),
                    dismissButton: .default(Text("OK"))
                )
            } else {
                return Alert(
                    title: Text("Ping Result"),
                    message: Text(
                        "\(pingMessage ?? "Pong!")\nLatency: \(pingLatency ?? "Unknown")"
                    ),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }

    private func pingBot() {
        guard bot.isActive, !isPinging else { return }

        isPinging = true
        pingError = nil
        pingLatency = nil
        pingMessage = nil

        Task {
            let result = await bot.apiClient.ping()

            DispatchQueue.main.async {
                isPinging = false

                switch result {
                case .success(let latency, let message):
                    pingLatency = latency
                    pingMessage = message
                    pingError = nil
                case .failure(let error):
                    pingError = error
                    pingLatency = nil
                    pingMessage = nil
                }

                showPingResult = true
            }
        }
    }
}

// Helper components for the command list
struct CommandSection<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .foregroundColor(.tumGray3)
                .padding(.leading, 5)

            content
                .padding(.leading, 5)
        }
        .padding(.vertical, 5)
        .padding(.trailing, 5)
    }
}

struct CommandButton: View {
    let title: String
    let systemImage: String
    let description: String
    let isDisabled: Bool
    let action: () -> Void

    init(
        title: String,
        systemImage: String,
        description: String,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.description = description
        self.isDisabled = isDisabled
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: systemImage)
                    .font(.title3)
                    .foregroundColor(isDisabled ? .tumGray4 : .tumBlue)
                    .frame(width: 30)

                VStack(alignment: .leading) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(isDisabled ? .tumGray4 : .tumBlue)

                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.tumGray3)
                }

                Spacer()

                Image(systemName: "arrowshape.up.circle.fill")
                    .foregroundColor(isDisabled ? .tumGray4 : .tumBlue)
            }
            .padding()
            .background(Color.tumGray9)
            .cornerRadius(10)
            .shadow(color: Color.black.opacity(0.4), radius: 2, x: 0, y: 1)
        }
        .disabled(isDisabled)
        .overlay(
            Group {
                if isDisabled {
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.tumGray4.opacity(0.5), lineWidth: 1)
                }
            }
        )
    }
}

struct CommandRow: View {
    let title: String
    let description: String
    let systemImage: String

    var body: some View {
        HStack {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundColor(.tumBlueDark4)
                .frame(width: 30)

            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.tumBlueDark4)

                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.tumGray3)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.tumBlue)
        }
        .padding()
        .background(Color.tumGray9)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.4), radius: 2, x: 0, y: 1)
    }
}

#Preview {
    NavigationStack {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                CommandsView(bot: SampleData.shared.bot)
            }
            .padding()
        }
        .background(Color(.systemBackground))
        .modelContainer(SampleData.shared.modelContainer)

    }
}
