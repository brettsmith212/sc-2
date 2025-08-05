# sc-2 iOS App - Agent Instructions

## Project Overview

iOS SwiftUI app called sc-2 with notes functionality, camera integration, location services, and notifications.

## Build & Development Setup

### Prerequisites

- Xcode installed (for SDKs and toolchain)
- VS Code with Swift extension
- xcode-build-server (installed via Homebrew)

### Build Commands

#### Using VS Code Tasks (Recommended)

- **Cmd+Shift+B** - Default build task (iOS: Build Debug simulator)
- **Cmd+Shift+P** → "Tasks: Run Task" for other options:
  - `iOS: Build Debug (simulator)` - Build for simulator
  - `iOS: Clean` - Clean build artifacts
  - `iOS: Test (simulator)` - Run tests

#### Command Line

```bash
# Build for simulator
xcodebuild -project sc-2.xcodeproj -scheme sc-2 -configuration Debug -destination "platform=iOS Simulator,name=iPhone 16" -derivedDataPath build build

# Clean
xcodebuild -project sc-2.xcodeproj -scheme sc-2 clean

# Test
xcodebuild -project sc-2.xcodeproj -scheme sc-2 -destination "platform=iOS Simulator,name=iPhone 16" test
```

### VS Code Integration

- **Language Server**: SourceKit-LSP via Swift extension
- **Build Server**: xcode-build-server configured for sc-2.xcodeproj
- **Tasks**: Defined in `.vscode/tasks.json`
- **Debug**: Configured in `.vscode/launch.json`

### Project Structure

```
sc-2/
├── sc-2/
│   ├── sc-2App.swift                 # App entry point
│   ├── ContentView.swift             # Main view
│   ├── Models/
│   │   └── Note.swift                # Note data model
│   ├── Views/
│   │   ├── NotesListView.swift       # Notes list
│   │   ├── NoteDetailView.swift      # Note editor
│   │   ├── CameraView.swift          # Camera integration
│   │   ├── LocationPickerView.swift  # Location picker
│   │   └── ShareSheet.swift          # Share functionality
│   └── Services/
│       ├── LocationManager.swift     # Location services
│       └── NotificationManager.swift # Push notifications
├── sc-2.xcodeproj/
├── .vscode/
│   ├── tasks.json                    # Build tasks
│   └── launch.json                   # Debug config
└── buildServer.json                  # xcode-build-server config
```

### Key Dependencies

- SwiftUI (UI framework)
- PhotosUI (for PhotosPicker)
- CoreLocation (location services)
- UserNotifications (push notifications)
- MapKit (map display)

### Common Issues & Solutions

#### Build Errors

- **PhotosPickerItem not found**: Ensure `import PhotosUI` is present
- **Simulator not found**: Update destination in tasks.json to available simulator
- **Location delegate warnings**: These are Swift 6 concurrency warnings, app still builds

#### VS Code Setup

- Run `xcode-build-server config -project sc-2.xcodeproj -scheme sc-2` if LSP isn't working
- Ensure buildServer.json exists in project root
- Check that Swift extension is installed and active

### Debugging

- Use VS Code debug panel with "Debug iOS App (Simulator)" configuration
- Attach to running app process for debugging
- LLDB available through VS Code terminal

### Notes

- Project builds successfully with warnings (no errors)
- Uses iPhone 16 simulator by default
- Build artifacts go to `build/` directory
- xcode-build-server provides LSP integration for VS Code
