import Foundation
import SwiftData

// Data model, response, and result type definitions have been moved to Models/DTOs.swift for better organization and separation of concerns.

@Model
class APIClient {

    var serverIP: String
    var apiKey: String

    init(serverIP: String, apiKey: String) {
        self.serverIP = serverIP
        self.apiKey = apiKey
    }

    func checkServerStatus() async -> Bool {
        guard let url = URL(string: "\(serverIP)/") else {
            print("DEBUG: Invalid server URL in APIClient: \(serverIP)/")
            return false
        }

        print("DEBUG: APIClient checking server status at \(serverIP)/")
        do {
            let (_, response) = try await URLSession.shared.data(from: url)
            let isOnline = (response as? HTTPURLResponse)?.statusCode == 200
            print(
                "DEBUG: APIClient server status check result: \(isOnline ? "online" : "offline")"
            )
            return isOnline
        } catch {
            print("DEBUG: APIClient failed to check server status: \(error)")
            return false
        }
    }

    func startBot() async -> Bool {
        guard let url = URL(string: "\(serverIP)/api/start-bot?api_key=\(apiKey)")
        else {
            print("DEBUG: Invalid server URL in APIClient: \(serverIP)/")
            return false
        }

        print("DEBUG: APIClient starting bot at \(serverIP)/")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            let isActive = (response as? HTTPURLResponse)?.statusCode == 200

            print(
                "DEBUG: APIClient bot start result: \(isActive ? "online" : "offline")"
            )

            return isActive
        } catch {
            print("DEBUG: APIClient failed to start bot: \(error)")
            return false
        }
    }
    
    func stopBot() async -> Bool {
        guard let url = URL(string: "\(serverIP)/api/stop-bot?api_key=\(apiKey)")
        else {
            print("DEBUG: Invalid server URL in APIClient: \(serverIP)/")
            return false
        }

        print("DEBUG: APIClient starting bot at \(serverIP)/")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            let isActive = (response as? HTTPURLResponse)?.statusCode == 200

            print(
                "DEBUG: APIClient bot start result: \(isActive ? "online" : "offline")"
            )

            return isActive
        } catch {
            print("DEBUG: APIClient failed to start bot: \(error)")
            return false
        }
    }

    func checkBotStatus() async -> Bool {
        guard let url = URL(string: "\(serverIP)/api/bot-status?api_key=\(apiKey)")
        else {
            print("DEBUG: Invalid server URL in APIClient: \(serverIP)/")
            return false
        }

        print("DEBUG: APIClient checking bot status status at \(serverIP)/")
        do {
            let (_, response) = try await URLSession.shared.data(from: url)
            let isActive = (response as? HTTPURLResponse)?.statusCode == 200
            print(
                "DEBUG: APIClient bot status check result: \(isActive ? "online" : "offline")"
            )

            return isActive
        } catch {
            print("DEBUG: APIClient failed to check bot status: \(error)")
            return false
        }
    }
    
    func sendHello(member: String, message: String) async -> HelloResult {
        guard let encodedMessage = message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(serverIP)/api/hello?api_key=\(apiKey)&member=\(member)&message=\(encodedMessage)")
        else {
            print("DEBUG: Invalid URL for sendHello in APIClient")
            return .failure(message: "Invalid URL")
        }

        print("DEBUG: APIClient sending hello message to member \(member)")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("DEBUG: Invalid HTTP response")
                return .failure(message: "Invalid HTTP response")
            }
            
            // Try to decode the JSON response
            let decoder = JSONDecoder()
            do {
                // Try to decode a standard API response
                struct HelloResponse: Codable {
                    let status: String
                    let message: String
                }
                
                let helloResponse = try decoder.decode(HelloResponse.self, from: data)
                
                if helloResponse.status == "success" {
                    print("DEBUG: APIClient send hello success: \(helloResponse.message)")
                    return .success(message: helloResponse.message)
                } else {
                    print("DEBUG: APIClient send hello failed: \(helloResponse.message)")
                    return .failure(message: helloResponse.message)
                }
            } catch {
                // If can't decode as standard format, try to decode as error message
                do {
                    if let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        if let errorMessage = jsonObject["message"] as? String {
                            return .failure(message: errorMessage)
                        }
                    }
                    
                    // Try to get string data for debugging
                    if let stringData = String(data: data, encoding: .utf8) {
                        print("DEBUG: Raw response: \(stringData)")
                        return .failure(message: "Unexpected response format: \(stringData)")
                    }
                } catch {
                    // Just fall through to status code check
                }
                
                // If we can't decode the response, check the status code
                if httpResponse.statusCode == 200 {
                    return .success(message: "Message sent successfully")
                } else {
                    return .failure(message: "Failed with status code: \(httpResponse.statusCode)")
                }
            }
        } catch {
            print("DEBUG: APIClient failed to send hello message: \(error)")
            return .failure(message: error.localizedDescription)
        }
    }

    func fetchMemberCount() async -> MemberCountResult {
        guard
            let url = URL(
                string: "\(serverIP)/api/member-count?api_key=\(apiKey)"
            )
        else {
            print("DEBUG: Invalid member count URL in APIClient")
            return .failure
        }

        print("DEBUG: APIClient fetching member count at \(url.absoluteString)")

        do {
            let (data, response) = try await URLSession.shared.data(from: url)

            guard response is HTTPURLResponse else {
                print("DEBUG: Invalid HTTP response")
                return .failure
            }

            // Try to decode the JSON response
            let decoder = JSONDecoder()
            let memberCountResponse = try decoder.decode(
                MemberCountResponse.self,
                from: data
            )

            // Check the status in the response
            if memberCountResponse.status == "success",
                let data = memberCountResponse.data
            {
                print("DEBUG: Successfully fetched member count: \(data)")
                return .success(
                    online: data.online,
                    offline: data.offline,
                    total: data.total
                )
            } else {
                print(
                    "DEBUG: Member count API returned status: \(memberCountResponse.status), message: \(memberCountResponse.message ?? "None")"
                )
                return .failure
            }
        } catch {
            print("DEBUG: Failed to fetch member count: \(error)")
            return .failure
        }
    }

    func fetchMembers() async -> MembersResult {
        guard let url = URL(string: "\(serverIP)/api/members?api_key=\(apiKey)") else {
            print("DEBUG: Invalid members URL in APIClient")
            return .failure("Invalid URL")
        }
        
        print("DEBUG: APIClient fetching members at \(url.absoluteString)")
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("DEBUG: Invalid HTTP response")
                return .failure("Invalid HTTP response")
            }
            
            if httpResponse.statusCode != 200 {
                print("DEBUG: HTTP error: \(httpResponse.statusCode)")
                return .failure("HTTP error: \(httpResponse.statusCode)")
            }
            
            // Try to decode the JSON response
            let decoder = JSONDecoder()
            let membersResponse = try decoder.decode(MembersResponse.self, from: data)
            
            // Check the status in the response
            if membersResponse.status == "success", let membersData = membersResponse.data {
                // Flatten the dictionary of guild members into a single array
                let allMembers = membersData.values.flatMap { $0 }
                print("DEBUG: Successfully fetched \(allMembers.count) members")
                return .success(members: allMembers)
            } else {
                let errorMessage = membersResponse.message ?? "Unknown error"
                print("DEBUG: Members API returned status: \(membersResponse.status), message: \(errorMessage)")
                return .failure(errorMessage)
            }
        } catch {
            print("DEBUG: Failed to fetch members: \(error)")
            return .failure(error.localizedDescription)
        }
    }

    func fetchRoles() async -> RolesResult {
        guard let url = URL(string: "\(serverIP)/api/roles?api_key=\(apiKey)") else {
            print("DEBUG: Invalid roles URL in APIClient")
            return .failure("Invalid URL")
        }
        
        print("DEBUG: APIClient fetching roles at \(url.absoluteString)")
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("DEBUG: Invalid HTTP response")
                return .failure("Invalid HTTP response")
            }
            
            if httpResponse.statusCode != 200 {
                print("DEBUG: HTTP error: \(httpResponse.statusCode)")
                return .failure("HTTP error: \(httpResponse.statusCode)")
            }
            
            // Try to decode the JSON response
            let decoder = JSONDecoder()
            let rolesResponse = try decoder.decode(RolesResponse.self, from: data)
            
            // Check the status in the response
            if rolesResponse.status == "success", let rolesData = rolesResponse.data {
                // Flatten the dictionary of guild roles into a single array
                let allRoles = rolesData.values.flatMap { $0 }
                print("DEBUG: Successfully fetched \(allRoles.count) roles")
                return .success(roles: allRoles)
            } else {
                let errorMessage = rolesResponse.message ?? "Unknown error"
                print("DEBUG: Roles API returned status: \(rolesResponse.status), message: \(errorMessage)")
                return .failure(errorMessage)
            }
        } catch {
            print("DEBUG: Failed to fetch roles: \(error)")
            return .failure(error.localizedDescription)
        }
    }
    
    func giveMemberRole(userId: String, roleId: String) async -> GiveRoleResult {
        guard let url = URL(string: "\(serverIP)/api/give-member-role?api_key=\(apiKey)&role_id=\(roleId)&user_id=\(userId)") else {
            print("DEBUG: Invalid URL for give-member-role in APIClient")
            return .failure(message: "Invalid URL")
        }
        
        print("DEBUG: APIClient assigning role \(roleId) to member \(userId)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard response is HTTPURLResponse else {
                print("DEBUG: Invalid HTTP response")
                return .failure(message: "Invalid HTTP response")
            }
            
            // Try to decode the JSON response
            let decoder = JSONDecoder()
            let giveRoleResponse = try decoder.decode(GiveRoleResponse.self, from: data)
            
            // Check the status in the response
            if giveRoleResponse.status == "success" {
                print("DEBUG: Successfully assigned role: \(giveRoleResponse.message)")
                return .success(message: giveRoleResponse.message)
            } else {
                print("DEBUG: Failed to assign role: \(giveRoleResponse.message)")
                return .failure(message: giveRoleResponse.message)
            }
        } catch {
            print("DEBUG: Failed to assign role: \(error)")
            return .failure(message: error.localizedDescription)
        }
    }

    func ping() async -> PingResult {
        guard let url = URL(string: "\(serverIP)/api/ping?api_key=\(apiKey)") else {
            print("DEBUG: Invalid ping URL in APIClient")
            return .failure("Invalid URL")
        }
        
        print("DEBUG: APIClient pinging server at \(url.absoluteString)")
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("DEBUG: Invalid HTTP response")
                return .failure("Invalid HTTP response")
            }
            
            if httpResponse.statusCode != 200 {
                print("DEBUG: HTTP error: \(httpResponse.statusCode)")
                return .failure("HTTP error: \(httpResponse.statusCode)")
            }
            
            // Try to decode the JSON response
            let decoder = JSONDecoder()
            let pingResponse = try decoder.decode(PingResponse.self, from: data)
            
            // Check the status in the response
            if pingResponse.status == "success" {
                print("DEBUG: Ping successful with latency: \(pingResponse.latency)")
                return .success(latency: pingResponse.latency, message: pingResponse.message)
            } else {
                print("DEBUG: Ping API returned status: \(pingResponse.status)")
                return .failure("Ping failed: \(pingResponse.message)")
            }
        } catch {
            print("DEBUG: Failed to ping: \(error)")
            return .failure(error.localizedDescription)
        }
    }

    func fetchChannels() async -> ChannelsResult {
        guard let url = URL(string: "\(serverIP)/api/channels?api_key=\(apiKey)") else {
            print("DEBUG: Invalid channels URL in APIClient")
            return .failure("Invalid URL")
        }
        
        print("DEBUG: APIClient fetching channels at \(url.absoluteString)")
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("DEBUG: Invalid HTTP response")
                return .failure("Invalid HTTP response")
            }
            
            if httpResponse.statusCode != 200 {
                print("DEBUG: HTTP error: \(httpResponse.statusCode)")
                return .failure("HTTP error: \(httpResponse.statusCode)")
            }
            
            // Try to decode the JSON response
            let decoder = JSONDecoder()
            let channelsResponse = try decoder.decode(ChannelsResponse.self, from: data)
            
            // Check the status in the response
            if channelsResponse.status == "success", let channelsData = channelsResponse.data {
                // Flatten the dictionary of guild channels into a single array
                let allChannels = channelsData.values.flatMap { $0 }
                print("DEBUG: Successfully fetched \(allChannels.count) channels")
                return .success(channels: allChannels)
            } else {
                let errorMessage = channelsResponse.message ?? "Unknown error"
                print("DEBUG: Channels API returned status: \(channelsResponse.status), message: \(errorMessage)")
                return .failure(errorMessage)
            }
        } catch {
            print("DEBUG: Failed to fetch channels: \(error)")
            return .failure(error.localizedDescription)
        }
    }
    
    func clearMessages(channelId: String, limit: Int) async -> ClearResult {
        guard let url = URL(string: "\(serverIP)/api/clear?api_key=\(apiKey)&channel_id=\(channelId)&limit=\(limit)") else {
            print("DEBUG: Invalid URL for clear-messages in APIClient")
            return .failure(message: "Invalid URL")
        }
        
        print("DEBUG: APIClient clearing \(limit) messages from channel \(channelId)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard response is HTTPURLResponse else {
                print("DEBUG: Invalid HTTP response")
                return .failure(message: "Invalid HTTP response")
            }
            
            // Try to decode the JSON response
            let decoder = JSONDecoder()
            let clearResponse = try decoder.decode(ClearResponse.self, from: data)
            
            // Check the status in the response
            if clearResponse.status == "success" {
                print("DEBUG: Successfully cleared messages: \(clearResponse.message)")
                return .success(message: clearResponse.message)
            } else {
                print("DEBUG: Failed to clear messages: \(clearResponse.message)")
                return .failure(message: clearResponse.message)
            }
        } catch {
            print("DEBUG: Failed to clear messages: \(error)")
            return .failure(message: error.localizedDescription)
        }
    }

    func createComplexSurvey(message: String, mainTopic: String, channelId: String, questions: [(text: String, buttonType: String)], duration: Int = 60) async -> ComplexSurveyResult {
        // Build URL with parameters
        var urlComponents = URLComponents(string: "\(serverIP)/api/create-complex-survey")
        var queryItems = [
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "message", value: message),
            URLQueryItem(name: "main_topic", value: mainTopic),
            URLQueryItem(name: "channel_id", value: channelId),
            URLQueryItem(name: "duration", value: "\(duration)")
        ]
        
        // Add questions and button types
        for (index, question) in questions.enumerated() {
            let questionNumber = index + 1
            queryItems.append(URLQueryItem(name: "question_\(questionNumber)", value: question.text))
            queryItems.append(URLQueryItem(name: "button_\(questionNumber)", value: question.buttonType))
        }
        
        urlComponents?.queryItems = queryItems
        
        guard let url = urlComponents?.url else {
            print("DEBUG: Invalid URL for create-complex-survey in APIClient")
            return .failure(message: "Invalid URL")
        }
        
        print("DEBUG: APIClient creating complex survey with \(questions.count) questions")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard response is HTTPURLResponse else {
                print("DEBUG: Invalid HTTP response")
                return .failure(message: "Invalid HTTP response")
            }
            
            // Try to decode the JSON response
            let decoder = JSONDecoder()
            let surveyResponse = try decoder.decode(ComplexSurveyResponse.self, from: data)
            
            // Check the status in the response
            if surveyResponse.status == "success" {
                print("DEBUG: Successfully created survey: \(surveyResponse.message)")
                return .success(message: surveyResponse.message)
            } else {
                print("DEBUG: Failed to create survey: \(surveyResponse.message)")
                return .failure(message: surveyResponse.message)
            }
        } catch {
            print("DEBUG: Failed to create survey: \(error)")
            return .failure(message: error.localizedDescription)
        }
    }

    func createSimpleSurvey(message: String, mainTopic: String, channelId: String, buttonType: String, duration: Int = 60) async -> SimpleSurveyResult {
        // Build URL with parameters
        var urlComponents = URLComponents(string: "\(serverIP)/api/create-simple-survey")
        let queryItems = [
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "message", value: message),
            URLQueryItem(name: "main_topic", value: mainTopic),
            URLQueryItem(name: "channel_id", value: channelId),
            URLQueryItem(name: "button_type", value: buttonType.lowercased()),
            URLQueryItem(name: "duration", value: "\(duration)")
        ]
        
        urlComponents?.queryItems = queryItems
        
        guard let url = urlComponents?.url else {
            print("DEBUG: Invalid URL for create-simple-survey in APIClient")
            return .failure(message: "Invalid URL")
        }
        
        print("DEBUG: APIClient creating simple survey with \(buttonType) buttons")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard response is HTTPURLResponse else {
                print("DEBUG: Invalid HTTP response")
                return .failure(message: "Invalid HTTP response")
            }
            
            // Try to decode the JSON response
            let decoder = JSONDecoder()
            let surveyResponse = try decoder.decode(SimpleSurveyResponse.self, from: data)
            
            // Check the status in the response
            if surveyResponse.status == "success" {
                print("DEBUG: Successfully created simple survey: \(surveyResponse.message)")
                return .success(message: surveyResponse.message)
            } else {
                print("DEBUG: Failed to create simple survey: \(surveyResponse.message)")
                return .failure(message: surveyResponse.message)
            }
        } catch {
            print("DEBUG: Failed to create simple survey: \(error)")
            return .failure(message: error.localizedDescription)
        }
    }

    func manageAttendance(groupId: String, targetUserId: String, status: Bool, code: String) async -> AttendanceResult {
        // Build URL with parameters
        let statusString = status ? "start" : "stop"
        var urlComponents = URLComponents(string: "\(serverIP)/api/attendance")
        let queryItems = [
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "status", value: statusString),
            URLQueryItem(name: "target_user_id", value: targetUserId),
            URLQueryItem(name: "code", value: code),
            URLQueryItem(name: "group_id", value: groupId.lowercased())
        ]
        
        urlComponents?.queryItems = queryItems
        
        guard let url = urlComponents?.url else {
            print("DEBUG: Invalid URL for attendance in APIClient")
            return .failure(message: "Invalid URL")
        }
        
        print("DEBUG: APIClient \(statusString)ing attendance for group \(groupId) with code \(code)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard response is HTTPURLResponse else {
                print("DEBUG: Invalid HTTP response")
                return .failure(message: "Invalid HTTP response")
            }
            
            // Try to decode the JSON response
            let decoder = JSONDecoder()
            let attendanceResponse = try decoder.decode(AttendanceResponse.self, from: data)
            
            // Check the status in the response
            if attendanceResponse.status == "success" {
                print("DEBUG: Successfully managed attendance: \(attendanceResponse.message)")
                return .success(message: attendanceResponse.message)
            } else {
                print("DEBUG: Failed to manage attendance: \(attendanceResponse.message)")
                return .failure(message: attendanceResponse.message)
            }
        } catch {
            print("DEBUG: Failed to manage attendance: \(error)")
            return .failure(message: error.localizedDescription)
        }
    }

    func fetchAttendanceFiles() async -> AttendanceFilesResult {
        guard let url = URL(string: "\(serverIP)/api/data/attendance?api_key=\(apiKey)") else {
            print("DEBUG: Invalid URL for fetch-attendance-files in APIClient")
            return .failure(message: "Invalid URL")
        }
        
        print("DEBUG: APIClient fetching attendance files at \(url.absoluteString)")
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("DEBUG: Invalid HTTP response")
                return .failure(message: "Invalid HTTP response")
            }
            
            if httpResponse.statusCode != 200 {
                print("DEBUG: HTTP error: \(httpResponse.statusCode)")
                return .failure(message: "HTTP error: \(httpResponse.statusCode)")
            }
            
            // Try to decode the JSON response
            let decoder = JSONDecoder()
            let filesResponse = try decoder.decode(AttendanceFilesResponse.self, from: data)
            
            print("DEBUG: Successfully fetched \(filesResponse.files.count) attendance files")
            return .success(files: filesResponse.files)
        } catch {
            print("DEBUG: Failed to fetch attendance files: \(error)")
            return .failure(message: error.localizedDescription)
        }
    }

    func fetchAttendanceContent(fileName: String) async -> AttendanceContentResult {
        guard let url = URL(string: "\(serverIP)/api/data/attendance?api_key=\(apiKey)&file=\(fileName)") else {
            print("DEBUG: Invalid URL for fetch-attendance-content in APIClient")
            return .failure(message: "Invalid URL")
        }
        
        print("DEBUG: APIClient fetching attendance content at \(url.absoluteString)")
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("DEBUG: Invalid HTTP response")
                return .failure(message: "Invalid HTTP response")
            }
            
            if httpResponse.statusCode != 200 {
                print("DEBUG: HTTP error: \(httpResponse.statusCode)")
                return .failure(message: "HTTP error: \(httpResponse.statusCode)")
            }
            
            // Try to decode the JSON response
            let decoder = JSONDecoder()
            let contentResponse = try decoder.decode(AttendanceContentResponse.self, from: data)
            
            print("DEBUG: Successfully fetched attendance content with \(contentResponse.content.count) entries")
            return .success(content: contentResponse.content)
        } catch {
            print("DEBUG: Failed to fetch attendance content: \(error)")
            return .failure(message: error.localizedDescription)
        }
    }

    func fetchFeedbackFiles() async -> FeedbackFilesResult {
        guard let url = URL(string: "\(serverIP)/api/data/feedback?api_key=\(apiKey)") else {
            print("DEBUG: Invalid URL for fetch-feedback-files in APIClient")
            return .failure(message: "Invalid URL")
        }
        
        print("DEBUG: APIClient fetching feedback files at \(url.absoluteString)")
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("DEBUG: Invalid HTTP response")
                return .failure(message: "Invalid HTTP response")
            }
            
            if httpResponse.statusCode != 200 {
                print("DEBUG: HTTP error: \(httpResponse.statusCode)")
                return .failure(message: "HTTP error: \(httpResponse.statusCode)")
            }
            
            // Try to decode the JSON response
            let decoder = JSONDecoder()
            let filesResponse = try decoder.decode(FeedbackFilesResponse.self, from: data)
            
            print("DEBUG: Successfully fetched \(filesResponse.files.count) feedback files")
            return .success(files: filesResponse.files)
        } catch {
            print("DEBUG: Failed to fetch feedback files: \(error)")
            return .failure(message: error.localizedDescription)
        }
    }

    func fetchFeedbackContent(fileName: String) async -> FeedbackContentResult {
        guard let url = URL(string: "\(serverIP)/api/data/feedback?api_key=\(apiKey)&file=\(fileName)") else {
            print("DEBUG: Invalid URL for fetch-feedback-content in APIClient")
            return .failure(message: "Invalid URL")
        }
        
        print("DEBUG: APIClient fetching feedback content at \(url.absoluteString)")
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("DEBUG: Invalid HTTP response")
                return .failure(message: "Invalid HTTP response")
            }
            
            if httpResponse.statusCode != 200 {
                print("DEBUG: HTTP error: \(httpResponse.statusCode)")
                return .failure(message: "HTTP error: \(httpResponse.statusCode)")
            }
            
            // Try to decode the JSON response
            let decoder = JSONDecoder()
            let contentResponse = try decoder.decode(FeedbackContentResponse.self, from: data)
            
            print("DEBUG: Successfully fetched feedback content with \(contentResponse.content.count) entries")
            return .success(content: contentResponse.content)
        } catch {
            print("DEBUG: Failed to fetch feedback content: \(error)")
            return .failure(message: error.localizedDescription)
        }
    }

    func fetchSurveyFiles() async -> SurveyFilesResult {
        guard let url = URL(string: "\(serverIP)/api/data/surveys?api_key=\(apiKey)") else {
            print("DEBUG: Invalid URL for fetch-survey-files in APIClient")
            return .failure(message: "Invalid URL")
        }
        
        print("DEBUG: APIClient fetching survey files at \(url.absoluteString)")
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("DEBUG: Invalid HTTP response")
                return .failure(message: "Invalid HTTP response")
            }
            
            if httpResponse.statusCode != 200 {
                print("DEBUG: HTTP error: \(httpResponse.statusCode)")
                return .failure(message: "HTTP error: \(httpResponse.statusCode)")
            }
            
            // Try to decode the JSON response
            let decoder = JSONDecoder()
            let filesResponse = try decoder.decode(SurveyFilesResponse.self, from: data)
            
            print("DEBUG: Successfully fetched \(filesResponse.files.count) survey files")
            return .success(files: filesResponse.files)
        } catch {
            print("DEBUG: Failed to fetch survey files: \(error)")
            return .failure(message: error.localizedDescription)
        }
    }

    func fetchSurveyContent(fileName: String) async -> SurveyContentResult {
        guard let encodedFileName = fileName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(serverIP)/api/data/surveys?api_key=\(apiKey)&file=\(encodedFileName)") else {
            print("DEBUG: Invalid URL for fetch-survey-content in APIClient")
            return .failure(message: "Invalid URL")
        }
        
        print("DEBUG: APIClient fetching survey content at \(url.absoluteString)")
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("DEBUG: Invalid HTTP response")
                return .failure(message: "Invalid HTTP response")
            }
            
            if httpResponse.statusCode != 200 {
                print("DEBUG: HTTP error: \(httpResponse.statusCode)")
                return .failure(message: "HTTP error: \(httpResponse.statusCode)")
            }
            
            // Try to decode the JSON response
            let decoder = JSONDecoder()
            let contentResponse = try decoder.decode(SurveyContentResponse.self, from: data)
            
            print("DEBUG: Successfully fetched survey content with \(contentResponse.content.count) entries")
            return .success(content: contentResponse.content)
        } catch {
            print("DEBUG: Failed to fetch survey content: \(error)")
            return .failure(message: error.localizedDescription)
        }
    }

    // Function to update the bot's development mode
    func updateDevelopmentMode(_ isDeveloperMode: Bool) async -> BotSettingsResult {
        // The endpoint is /api/settings/bot/development_mode
        
        guard let url = URL(string: "\(serverIP)/api/settings/bot/development_mode?api_key=\(apiKey)&development_mode=\(isDeveloperMode)") else {
            print("DEBUG: Invalid URL for updateDevelopmentMode in APIClient")
            return .failure(message: "Invalid URL")
        }
        
        print("DEBUG: APIClient updating development mode to \(isDeveloperMode)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("DEBUG: Invalid HTTP response")
                return .failure(message: "Invalid HTTP response")
            }
            
            // Try to decode the JSON response
            do {
                struct SettingsResponse: Codable {
                    let status: String
                    let message: String
                }
                
                let decoder = JSONDecoder()
                let settingsResponse = try decoder.decode(SettingsResponse.self, from: data)
                
                if settingsResponse.status == "success" {
                    print("DEBUG: Successfully updated development mode: \(settingsResponse.message)")
                    return .success(message: settingsResponse.message)
                } else {
                    print("DEBUG: Failed to update development mode: \(settingsResponse.message)")
                    return .failure(message: settingsResponse.message)
                }
            } catch {
                // If we can't decode the response, try to get the raw response
                if let stringData = String(data: data, encoding: .utf8) {
                    print("DEBUG: Raw response: \(stringData)")
                    return .failure(message: "Failed to parse response: \(stringData)")
                }
                
                // If we can't decode the response, check the status code
                if httpResponse.statusCode == 200 {
                    return .success(message: "Development mode updated successfully")
                } else {
                    return .failure(message: "Failed with status code: \(httpResponse.statusCode)")
                }
            }
        } catch {
            print("DEBUG: Failed to update development mode: \(error)")
            return .failure(message: error.localizedDescription)
        }
    }
    
    // Function to update the bot's token
    func updateBotToken(isDeveloperMode: Bool, token: String) async -> BotSettingsResult {
        // Skip if token is empty
        if token.isEmpty {
            print("DEBUG: Token is empty, skipping token update")
            return .success(message: "No token to update")
        }
        
        // Determine which endpoint to use based on development mode
        let endpoint = isDeveloperMode ? "dev_token" : "token"
        let paramName = isDeveloperMode ? "dev_token" : "token"
        
        guard let encodedToken = token.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(serverIP)/api/settings/bot/\(endpoint)?api_key=\(apiKey)&\(paramName)=\(encodedToken)") else {
            print("DEBUG: Invalid URL for updateBotToken in APIClient")
            return .failure(message: "Invalid URL")
        }
        
        print("DEBUG: APIClient updating \(isDeveloperMode ? "developer" : "regular") token")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("DEBUG: Invalid HTTP response")
                return .failure(message: "Invalid HTTP response")
            }
            
            // Try to decode the JSON response
            do {
                struct SettingsResponse: Codable {
                    let status: String
                    let message: String
                }
                
                let decoder = JSONDecoder()
                let settingsResponse = try decoder.decode(SettingsResponse.self, from: data)
                
                if settingsResponse.status == "success" {
                    print("DEBUG: Successfully updated token: \(settingsResponse.message)")
                    return .success(message: settingsResponse.message)
                } else {
                    print("DEBUG: Failed to update token: \(settingsResponse.message)")
                    return .failure(message: settingsResponse.message)
                }
            } catch {
                // If we can't decode the response, try to get the raw response
                if let stringData = String(data: data, encoding: .utf8) {
                    print("DEBUG: Raw response: \(stringData)")
                    return .failure(message: "Failed to parse response: \(stringData)")
                }
                
                // If we can't decode the response, check the status code
                if httpResponse.statusCode == 200 {
                    return .success(message: "Token updated successfully")
                } else {
                    return .failure(message: "Failed with status code: \(httpResponse.statusCode)")
                }
            }
        } catch {
            print("DEBUG: Failed to update token: \(error)")
            return .failure(message: error.localizedDescription)
        }
    }

    // Function to update groups
    func updateGroups(groups: [String]) async -> UpdateGroupsResult {
        guard let url = URL(string: "\(serverIP)/api/settings/groups?api_key=\(apiKey)") else {
            print("DEBUG: Invalid URL for updateGroups in APIClient")
            return .failure(message: "Invalid URL")
        }
        
        print("DEBUG: APIClient updating groups: \(groups)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Create the JSON payload
        let payload: [String: [String]] = ["groups": groups]
        
        do {
            // Convert payload to JSON data
            let jsonData = try JSONSerialization.data(withJSONObject: payload)
            request.httpBody = jsonData
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("DEBUG: Invalid HTTP response")
                return .failure(message: "Invalid HTTP response")
            }
            
            // Try to decode the JSON response
            do {
                struct GroupsResponse: Codable {
                    let status: String
                    let message: String
                    let data: GroupsData?
                    
                    struct GroupsData: Codable {
                        let groups: [String]
                    }
                }
                
                let decoder = JSONDecoder()
                let groupsResponse = try decoder.decode(GroupsResponse.self, from: data)
                
                if groupsResponse.status == "success" {
                    print("DEBUG: Successfully updated groups: \(groupsResponse.message)")
                    return .success(message: groupsResponse.message)
                } else {
                    print("DEBUG: Failed to update groups: \(groupsResponse.message)")
                    return .failure(message: groupsResponse.message)
                }
            } catch {
                // If we can't decode the response, try to get the raw response
                if let stringData = String(data: data, encoding: .utf8) {
                    print("DEBUG: Raw response: \(stringData)")
                    return .failure(message: "Failed to parse response: \(stringData)")
                }
                
                // If we can't decode the response, check the status code
                if httpResponse.statusCode == 200 {
                    return .success(message: "Groups updated successfully")
                } else {
                    return .failure(message: "Failed with status code: \(httpResponse.statusCode)")
                }
            }
        } catch {
            print("DEBUG: Failed to update groups: \(error)")
            return .failure(message: error.localizedDescription)
        }
    }

    // Function to fetch settings from the server
    func fetchSettings() async -> Result<BotSettings, Error> {
        guard let url = URL(string: "\(serverIP)/api/settings?api_key=\(apiKey)") else {
            return .failure(NSError(domain: "APIClient", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]))
        }
        
        print("DEBUG: APIClient fetching settings from \(url.absoluteString)")
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(NSError(domain: "APIClient", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid HTTP response"]))
            }
            
            // Try to decode the JSON response
            do {
                let decoder = JSONDecoder()
                let settingsResponse = try decoder.decode(SettingsResponse.self, from: data)
                
                if settingsResponse.status == "success", let settingsData = settingsResponse.data {
                    print("DEBUG: Successfully fetched settings")
                    let settings = BotSettings(
                        developmentMode: settingsData.bot.developmentMode,
                        token: settingsData.bot.token,
                        devToken: settingsData.bot.devToken,
                        groups: settingsData.groups,
                        accessRoles: settingsData.accessRoles
                    )
                    return .success(settings)
                } else {
                    let errorMessage = settingsResponse.message ?? "Unknown error"
                    print("DEBUG: Settings API returned status: \(settingsResponse.status), message: \(errorMessage)")
                    return .failure(NSError(domain: "APIClient", code: 3, userInfo: [NSLocalizedDescriptionKey: errorMessage]))
                }
            } catch {
                // If we can't decode the response, try to get the raw response
                if let stringData = String(data: data, encoding: .utf8) {
                    print("DEBUG: Raw response: \(stringData)")
                    return .failure(NSError(domain: "APIClient", code: 4, userInfo: [NSLocalizedDescriptionKey: "Failed to parse response: \(stringData)"]))
                }
                
                return .failure(error)
            }
        } catch {
            print("DEBUG: Failed to fetch settings: \(error)")
            return .failure(error)
        }
    }
    
}
