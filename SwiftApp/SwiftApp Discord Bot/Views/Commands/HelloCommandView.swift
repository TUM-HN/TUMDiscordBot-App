//
//  HelloCommandView.swift
//  DiscordApp_Demo
//
//  Created by Campus Heilbronn on 14.04.25.
//

import SwiftData
import SwiftUI

struct HelloCommandView: View {
    @Bindable var bot: Bot

    @State private var message = ""
    @State private var selectedMemberId: String?
    @State private var members: [Member] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var isSuccess = false
    @State private var isSending = false

    var body: some View {
        Form {
            Section(
                header: RequiredSectionHeader(text: "Message Command")
            ) {
                if isLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                            .padding()
                        Spacer()
                    }
                } else {
                    TextField("Message", text: $message)
                        .autocorrectionDisabled(true)
                    RequiredPicker(title: "Member", selection: $selectedMemberId) {
                        Text("Select a member").tag(nil as String?)
                        ForEach(members) { member in
                            Text(member.displayName).tag(member.id as String?)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())

                    // Send button
                    Button(isSending ? "Sending..." : "Send Greeting") {
                        sendHello()
                    }
                    .disabled(
                        selectedMemberId == nil || message.isEmpty || isSending
                    )
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 5)
                }
            }
            if isSuccess {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Message sent successfully!")
                        .foregroundColor(.green)
                }
                .padding(.vertical, 5)
            }

            if let error = errorMessage {
                HStack {
                    Text(error)
                        .foregroundColor(.red)
                        .padding(.top, 5)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.vertical, 5)
            }
        }
        .navigationTitle("Message Command")
        .onAppear {
            fetchMembers()
        }
        .refreshable {
            fetchMembers()
        }
    }

    private func fetchMembers() {
        isLoading = true
        errorMessage = nil

        Task {
            let result = await bot.apiClient.fetchMembers()

            DispatchQueue.main.async {
                isLoading = false

                switch result {
                case .success(let fetchedMembers):
                    self.members = fetchedMembers.sorted {
                        $0.displayName < $1.displayName
                    }
                case .failure(let error):
                    self.errorMessage = "Failed to load members: \(error)"
                }
            }
        }
    }

    private func sendHello() {
        guard let memberId = selectedMemberId, !message.isEmpty else { return }

        // Find the selected member name
        let selectedMember = members.first(where: { $0.id == memberId })
        let memberName = selectedMember?.displayName ?? "Unknown"

        isSending = true
        isSuccess = false
        errorMessage = nil

        Task {
            let result = await bot.apiClient.sendHello(
                member: memberId,
                message: message
            )

            DispatchQueue.main.async {
                isSending = false

                switch result {
                case .success(let message):
                    isSuccess = true
                    errorMessage = nil
                case .failure(let errorMsg):
                    isSuccess = false
                    // Format error message to include member name and ID
                    errorMessage =
                        "Failed to send message to \(memberName) (\(memberId)):\n\(errorMsg)"
                }
            }
        }
    }
}

#Preview {
    HelloCommandView(bot: SampleData.shared.bot)
        .modelContainer(
            SampleData.shared.modelContainer
        )
}
