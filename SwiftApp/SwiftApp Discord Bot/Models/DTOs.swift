import Foundation
import SwiftData

// MARK: - Member Count
struct MemberCountData: Codable {
    let offline: Int
    let online: Int
    let total: Int
}

struct MemberCountResponse: Codable {
    let data: MemberCountData?
    let status: String
    let message: String?
}

enum MemberCountResult {
    case success(online: Int, offline: Int, total: Int)
    case failure
}

// MARK: - Members
struct Member: Codable, Identifiable, Hashable {
    let avatarUrl: String?
    let bot: Bool
    let discriminator: String
    let displayName: String
    let id: String
    let joinedAt: String
    let name: String
    let roles: [String]
    let status: String
    
    enum CodingKeys: String, CodingKey {
        case avatarUrl = "avatar_url"
        case bot
        case discriminator
        case displayName = "display_name"
        case id
        case joinedAt = "joined_at"
        case name
        case roles
        case status
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Member, rhs: Member) -> Bool {
        lhs.id == rhs.id
    }
}

struct MembersData: Codable {
    let guildMembers: [String: [Member]]
    
    enum CodingKeys: String, CodingKey {
        case guildMembers = "data"
    }
}

struct MembersResponse: Codable {
    let data: [String: [Member]]?
    let status: String
    let message: String?
}

enum MembersResult {
    case success(members: [Member])
    case failure(String)
}

// MARK: - Roles
struct Role: Codable, Identifiable, Hashable {
    let color: String
    let id: String
    let mentionable: Bool
    let name: String
    let permissions: String
    let position: Int
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Role, rhs: Role) -> Bool {
        lhs.id == rhs.id
    }
}

struct RolesResponse: Codable {
    let data: [String: [Role]]?
    let status: String
    let message: String?
}

enum RolesResult {
    case success(roles: [Role])
    case failure(String)
}

// Response & Result for assigning a role
struct GiveRoleResponse: Codable {
    let status: String
    let message: String
}

enum GiveRoleResult {
    case success(message: String)
    case failure(message: String)
}

// MARK: - Ping
struct PingResponse: Codable {
    let latency: String
    let message: String
    let status: String
}

enum PingResult {
    case success(latency: String, message: String)
    case failure(String)
}

// MARK: - Channels
struct Channel: Codable, Identifiable, Hashable {
    let categoryId: String?
    let id: String
    let name: String
    let position: Int
    let type: String
    
    enum CodingKeys: String, CodingKey {
        case categoryId = "category_id"
        case id
        case name
        case position
        case type
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Channel, rhs: Channel) -> Bool {
        lhs.id == rhs.id
    }
}

struct ChannelsResponse: Codable {
    let data: [String: [Channel]]?
    let status: String
    let message: String?
}

enum ChannelsResult {
    case success(channels: [Channel])
    case failure(String)
}

// MARK: - Settings
struct AccessRole: Codable, Identifiable {
    let id: String
    let name: String
    let color: String
    let mentionable: Bool
    let permissions: String
    let position: Int
}

struct BotData: Codable {
    let token: String
    let devToken: String
    let developmentMode: Bool
    
    enum CodingKeys: String, CodingKey {
        case token
        case devToken = "dev_token"
        case developmentMode = "development_mode"
    }
}

struct SettingsData: Codable {
    let bot: BotData
    let groups: [String]
    let accessRoles: [AccessRole]
    
    enum CodingKeys: String, CodingKey {
        case bot
        case groups
        case accessRoles = "access_roles"
    }
}

struct SettingsResponse: Codable {
    let data: SettingsData?
    let status: String
    let message: String?
}

struct BotSettings {
    let developmentMode: Bool
    let token: String
    let devToken: String
    let groups: [String]
    let accessRoles: [AccessRole]
}

enum BotSettingsResult {
    case success(message: String)
    case failure(message: String)
}

enum UpdateGroupsResult {
    case success(message: String)
    case failure(message: String)
}

// MARK: - Clear messages
struct ClearResponse: Codable {
    let status: String
    let message: String
}

enum ClearResult {
    case success(message: String)
    case failure(message: String)
}

// MARK: - Surveys & Attendance
// Complex survey
struct ComplexSurveyResponse: Codable {
    let status: String
    let message: String
}

enum ComplexSurveyResult {
    case success(message: String)
    case failure(message: String)
}

// Simple survey
struct SimpleSurveyResponse: Codable {
    let status: String
    let message: String
}

enum SimpleSurveyResult {
    case success(message: String)
    case failure(message: String)
}

// Attendance
struct AttendanceResponse: Codable {
    let status: String
    let message: String
}

enum AttendanceResult {
    case success(message: String)
    case failure(message: String)
}

struct AttendanceFile: Codable, Identifiable {
    let created: String
    let modified: String
    let name: String
    let size: Int
    var id: String { name }
}

struct AttendanceFilesResponse: Codable {
    let files: [AttendanceFile]
}

enum AttendanceFilesResult {
    case success(files: [AttendanceFile])
    case failure(message: String)
}

struct AttendanceEntry: Codable {
    let Attendance: String
}

struct AttendanceContentResponse: Codable {
    let content: [AttendanceEntry]
}

enum AttendanceContentResult {
    case success(content: [AttendanceEntry])
    case failure(message: String)
}

// Feedback
struct FeedbackFile: Codable, Identifiable {
    let created: String
    let modified: String
    let name: String
    let size: Int
    var id: String { name }
}

struct FeedbackFilesResponse: Codable {
    let files: [FeedbackFile]
}

enum FeedbackFilesResult {
    case success(files: [FeedbackFile])
    case failure(message: String)
}

struct FeedbackEntry: Codable {
    let Feedback: String
    let Name: String
}

struct FeedbackContentResponse: Codable {
    let content: [FeedbackEntry]
}

enum FeedbackContentResult {
    case success(content: [FeedbackEntry])
    case failure(message: String)
}

// Surveys
struct SurveyFile: Codable, Identifiable {
    let created: String
    let modified: String
    let name: String
    let size: Int
    var id: String { name }
}

struct SurveyFilesResponse: Codable {
    let files: [SurveyFile]
}

enum SurveyFilesResult {
    case success(files: [SurveyFile])
    case failure(message: String)
}

struct SurveyEntry: Codable {
    let Name: String
    private let additionalData: [String: String]
    
    var responsePairs: [(key: String, value: String)] {
        additionalData.filter { $0.key != "Name" }
            .map { ($0.key, $0.value) }
            .sorted { $0.key < $1.key }
    }
    
    var responsePair: (key: String, value: String)? {
        additionalData.first { $0.key != "Name" }
    }
    
    enum CodingKeys: String, CodingKey {
        case Name
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicCodingKeys.self)
        Name = try container.decode(String.self, forKey: DynamicCodingKeys(stringValue: "Name")!)
        var data = [String: String]()
        for key in container.allKeys where key.stringValue != "Name" {
            data[key.stringValue] = try container.decode(String.self, forKey: key)
        }
        additionalData = data
    }
    
    struct DynamicCodingKeys: CodingKey {
        var stringValue: String
        var intValue: Int?
        init?(stringValue: String) { self.stringValue = stringValue }
        init?(intValue: Int) { stringValue = "\(intValue)"; self.intValue = intValue }
    }
}

struct SurveyContentResponse: Codable {
    let content: [SurveyEntry]
}

enum SurveyContentResult {
    case success(content: [SurveyEntry])
    case failure(message: String)
}

// MARK: - Hello
enum HelloResult {
    case success(message: String)
    case failure(message: String)
} 