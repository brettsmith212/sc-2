# sc-2 iOS App - Agent Instructions

## Project Overview

iOS SwiftUI app called sc-2 with UPS API integration for address validation and shipping rate calculations. Originally designed for notes functionality, camera integration, location services, and notifications, now focused on demonstrating UPS shipping services.

## Build & Development Setup

To build and run simulator, use the xcodebuildmcp commands.

### Prerequisites

- Xcode installed (for SDKs and toolchain)
- VS Code with Swift extension
- xcode-build-server (installed via Homebrew)

### VS Code Integration

- **Language Server**: SourceKit-LSP via Swift extension
- **Build Server**: xcode-build-server configured for sc-2.xcodeproj

### Project Structure

```
sc-2/
├── sc-2/
│   ├── sc-2App.swift                 # App entry point
│   ├── ContentView.swift             # Main view
│   ├── Config.swift                  # Configuration loader
│   ├── Models/
│   │   ├── UPSRatingModels.swift     # UPS Rating API models
│   │   ├── UPSAddressValidationModels.swift # UPS Address Validation models
│   │   └── UPSError.swift            # UPS error handling
│   ├── Views/
│   │   ├── RateCalculationView.swift # Rate calculation form
│   │   └── AddressValidationView.swift # Address validation form
│   ├── Services/
│   │   ├── UPSRatingService.swift    # UPS Rating API service
│   │   ├── UPSAddressValidationService.swift # UPS Address Validation service
│   │   └── UPSOAuthService.swift     # UPS OAuth authentication
│   └── Networking/
│       └── HTTPClient.swift          # HTTP networking layer
├── sc-2.xcodeproj/
├── Config.xcconfig                   # UPS API credentials
└── buildServer.json                  # xcode-build-server config
```

### Key Dependencies

- SwiftUI (UI framework)
- PhotosUI (for PhotosPicker)
- CoreLocation (location services)
- UserNotifications (push notifications)
- MapKit (map display)

### UPS API Configuration

#### Required Configuration Files

- **Config.xcconfig**: Contains UPS API credentials and base URLs

  - `UPS_CLIENT_ID=<YOUR_CLIENT_ID>`
  - `UPS_CLIENT_SECRET=<YOUR_CLIENT_SECRET>`
  - `UPS_ACCOUNT_NUMBER=<YOUR_ACCOUNT_NUMBER>`
  - `UPS_API_BASE_URL=https://wwwcie.ups.com`
  - `UPS_OAUTH_BASE_URL=https://wwwcie.ups.com`

- **Info.plist**: Maps configuration values for runtime access

#### UPS API Integration Learnings

- **URL Construction**: Ensure base URLs don't have trailing slashes when appending `/api` paths
- **Account Number Required**: UPS Rating API requires valid account number in `ShipperNumber` and `BillShipper.AccountNumber` fields
- **Error Handling**: UPS returns structured error responses with specific codes for different validation failures

### Common Issues & Solutions

#### Build Errors

- **PhotosPickerItem not found**: Ensure `import PhotosUI` is present
- **Simulator not found**: Update destination in tasks.json to available simulator
- **Location delegate warnings**: These are Swift 6 concurrency warnings, app still builds

#### UPS API Issues

- **400 Bad Request with missing account number**: Ensure `UPS_ACCOUNT_NUMBER` is set in Config.xcconfig and properly configured
- **URL construction errors**: Check that API base URLs don't have double slashes (e.g., `//api` instead of `/api`)
- **OAuth authentication failures**: Verify `UPS_CLIENT_ID` and `UPS_CLIENT_SECRET` are correct and valid
- **Rate calculation failures**: Ensure shipper and ship-from addresses have valid `ShipperNumber` set to account number

#### VS Code Setup & Diagnostics

- **Missing buildServer.json**: Run `xcode-build-server config -project sc-2.xcodeproj -scheme sc-2` to regenerate
- **SourceKit-LSP errors**: Restart VS Code language server (Cmd+Shift+P → "Swift: Restart Language Server")
- **Swift toolchain not found**: Check `.vscode/settings.json` has correct `swift.path` (use `/usr/bin/swift`)
- **Type resolution issues**: Ensure `.vscode/settings.json` has correct SourceKit-LSP configuration
- **Red squiggles but builds fine**: This is usually VS Code indexing - project builds correctly via Xcode tools
- Check that Swift extension is installed and active
- **After settings changes**: Restart VSCode completely for toolchain changes to take effect
- **If Swift extension fails**: Use minimal `.vscode/settings.json` with just file associations - syntax highlighting will work, but no IntelliSense

### Debugging

- Use VS Code debug panel with "Debug iOS App (Simulator)" configuration
- Attach to running app process for debugging
- LLDB available through VS Code terminal

### Notes

- Use `make run` to build, install, and launch on the simulator.
- Project builds successfully with warnings (no errors).
- Uses iPhone 16 simulator by default.
- Build artifacts go to `build/` directory.
- xcode-build-server provides LSP integration for VS Code.
