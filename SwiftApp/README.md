# SwiftApp Discord Bot

A SwiftUI application for managing Discord bots, featuring a modern interface, comprehensive command management, and real-time monitoring capabilities.

![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![Platform](https://img.shields.io/badge/Platform-iOS%2016.0+-blue)
![SwiftUI](https://img.shields.io/badge/Framework-SwiftUI-purple)
![SwiftData](https://img.shields.io/badge/Persistence-SwiftData-green)

## Features

- **Bot Management**: Create, configure, and manage multiple Discord bots
- **Command System**: Extensive command library including:
  - Simple messaging commands
  - Channel management
  - Role assignment
  - Complex surveys
  - Attendance tracking
- **Real-time Monitoring**: Live status updates for bot operations
- **SwiftData Integration**: Persistent storage for bot configurations
- **Modern SwiftUI Interface**: Responsive design with iOS 17 features

## Project Structure

```
SwiftApp Discord Bot/
|-- Models/
|   |-- Bot.swift           # Core data model with SwiftData integration
|   |-- APIClient.swift     # Network communication layer
|   `-- DTOs.swift          # Data transfer objects
|-- Views/
    |-- ContentView.swift   # Main app container view
    |-- BotView/            # Bot management interface
    |   |-- BotView.swift
    |   |-- HeaderView.swift
    |   `-- CommandsView.swift
    |-- Commands/           # Command-specific views
    |   |-- HelloCommandView.swift
    |   |-- ClearCommandView.swift
    |   |-- GiveRoleCommandView.swift
    |   `-- ...
    `-- SettingsView.swift  # Configuration interface
```

## Requirements

- iOS 18.2+
- Xcode 15.0+
- Swift 5.9+

## Installation

1. Open `SwiftApp Discord Bot.xcodeproj` in Xcode

2. Build and run the application on your target device or simulator

## Usage

### Bot Setup

1. Launch the application
2. Create a new bot with the "+" button
3. Configure server IP and API key
4. Start your bot with the toggle control

### Command Management

1. Navigate to your bot's detail view
2. Select from available commands in the command list
3. Configure command parameters
4. Execute commands directly from the interface

### Settings & Configuration

1. Access the settings screen from the bot detail view
2. Configure Discord-specific settings
3. Manage token authentication

## Architecture

This project follows a modern SwiftUI architecture with SwiftData for persistence:

- **MVVM Pattern**: Clear separation between views and business logic
- **SwiftData**: For object persistence and relationship management
- **Async/Await**: For clean, concurrent network operations
- **Testing and Accessibility**: XCTest is utilized for unit and integration tests. Accessibility identifiers are implemented throughout the application, forming a crucial foundation for interaction with assistive technologies and for future UI testing efforts.

## Testing

The project includes a comprehensive suite of unit and integration tests using XCTest. Accessibility identifiers have been integrated throughout the UI; these are vital for enabling assistive technologies and to support future UI testing efforts, though no UI test cases have been implemented at this stage.

Run the existing tests in Xcode using ⌘+U or through the Test Navigator.

## License

This project is proprietary and confidential.

## Acknowledgments

- SwiftUI framework and community
- Swift Data team for persistence framework
- Discord API documentation
