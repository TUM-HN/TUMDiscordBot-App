import Foundation
import SwiftData

// Define a model for groups
@Model
class GroupModel {
    var name: String
    var isValid: Bool
    var attendanceActive: Bool
    var attendanceCode: String?  // store the current active attendance code
    
    init(name: String, isValid: Bool = false, attendanceActive: Bool = false) {
        self.name = name
        self.isValid = isValid
        self.attendanceActive = attendanceActive
        self.attendanceCode = nil
    }
}

@Model
class Bot  {
    
    var name: String
    var apiClient: APIClient!
    var isActive: Bool
    var role: String
    var token: String?
    var devToken: String?
    var isDeveloperMode: Bool
    @Relationship(deleteRule: .cascade) var groups: [GroupModel] = []
    
    init(name: String, apiClient: APIClient!, role: String = "", token: String? = nil, devToken: String? = nil, isDeveloperMode: Bool = false) {
        self.name = name
        self.apiClient = apiClient
        self.role = role
        self.token = token
        self.devToken = devToken
        self.isDeveloperMode = isDeveloperMode
        self.isActive = false
        self.groups = [
            GroupModel(name: "G1", isValid: true),
            GroupModel(name: "G2", isValid: true)
        ]
    }
    
    static let sampleData = [
        Bot(
            name: "Master Mind",
            apiClient: APIClient(serverIP: "http://127.0.0.1:5000", apiKey: "025002"),
            token: "",
            devToken: ""
            )
    ]
}
