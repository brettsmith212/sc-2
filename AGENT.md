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
│   │   ├── AddressValidationView.swift # Address validation form
│   │   ├── LoginView.swift           # Authentication (Apple/Google Sign-In)
│   │   └── AuthenticatedView.swift   # Main app wrapper with auth state
│   ├── Services/
│   │   ├── UPSRatingService.swift    # UPS Rating API service
│   │   ├── UPSAddressValidationService.swift # UPS Address Validation service
│   │   ├── UPSOAuthService.swift     # UPS OAuth authentication
│   │   └── ConvexService.swift       # Convex backend service
│   ├── Views/
│   │   └── ConvexStatusView.swift    # Backend connection status
│   └── Networking/
│       └── HTTPClient.swift          # HTTP networking layer
├── sc-2.xcodeproj/
├── convex/                           # Convex backend
│   ├── schema.ts                     # Database schema (users, addresses, packages, rates, payments, shipments, tracking_events)
│   ├── test.ts                       # Test functions for connection verification
│   ├── users.ts                      # User management functions
│   ├── mobileAuth.ts                 # Mobile authentication HTTP endpoint
│   └── http.ts                       # HTTP routes for mobile API
├── Config.xcconfig                   # UPS API credentials
└── buildServer.json                  # xcode-build-server config
```

### Key Dependencies

- SwiftUI (UI framework)
- PhotosUI (for PhotosPicker)
- CoreLocation (location services)
- UserNotifications (push notifications)
- MapKit (map display)
- ConvexMobile (backend integration)
- AuthenticationServices (Apple Sign-In)
- GoogleSignIn + GoogleSignInSwift (Google authentication)

### UPS API Configuration

#### Required Configuration Files

- **Config.xcconfig**: Contains UPS API credentials and base URLs

  - `UPS_CLIENT_ID=<YOUR_CLIENT_ID>`
  - `UPS_CLIENT_SECRET=<YOUR_CLIENT_SECRET>`
  - `UPS_ACCOUNT_NUMBER=<YOUR_ACCOUNT_NUMBER>`
  - `UPS_API_BASE_URL=https://wwwcie.ups.com`
  - `UPS_OAUTH_BASE_URL=https://wwwcie.ups.com`

- **Info.plist**: Maps configuration values for runtime access

### Convex Backend Integration

#### Backend Setup

- **Deployment URL**: `https://hidden-labrador-91.convex.cloud`
- **Environment**: Development deployment managed via `.env.local`

#### Database Tables

- **test_entries**: Connection testing (temporary)
- **users**: User authentication and profiles (✅ implemented with Apple/Google Sign-In)
- **addresses**: Address management with validation (PoC ready)
- **packages**: Package dimensions and details (PoC ready)
- **rates**: Rate caching with expiration (PoC ready)
- **payments**: Payment processing and status tracking (PoC ready)
- **shipments**: Label creation and shipment management (PoC ready)
- **tracking_events**: Shipment tracking timeline (PoC ready)

#### Deployment Commands

**Deploy schema and function changes:**
```bash
npx convex dev --once
```

**Start continuous development mode:**
```bash
npx convex dev
```

**Important**: Run `npx convex dev --once` after making changes to:
- `convex/schema.ts` (database schema)
- `convex/*.ts` (backend functions)

#### Connection Status

- App displays real-time Convex connection status (green dot = connected)
- ConvexService provides singleton client for all backend operations
- Automatic connection testing on app launch

### Authentication

Apple Sign-In uses native AuthenticationServices framework and Google Sign-In uses GoogleSignIn iOS SDK, both creating users in Convex backend via mobile HTTP endpoint with local session persistence.

#### Authentication Setup

- **Apple Sign-In**: Native iOS with `SignInWithAppleButton` from `AuthenticationServices`
- **Google Sign-In**: Native iOS with `GoogleSignInButton` from `GoogleSignInSwift` 
- **Backend Integration**: HTTP endpoint `/mobile/register-user` stores user data in Convex
- **Session Management**: UserDefaults stores local session, checks on app launch
- **User Creation**: Both providers create/update users in Convex `users` table with unique `auth_user_id`

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
