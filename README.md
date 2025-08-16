# sc-2 iOS App

SwiftUI app with UPS Address Validation and Rating examples, integrated with Convex backend for data management.

## Prerequisites

- Xcode (with iOS Simulator)
- Node.js and npm (for Convex backend)
- xcode-build-server (for IDE language features). Install via Homebrew:
  ```bash
  brew install xcode-build-server
  ```

## Getting started

### 1. Set up the Convex Backend

First, install the Node.js dependencies and set up the Convex backend:

```bash
# Install dependencies
npm install

# Set up Convex (first time only - creates .env.local)
npx convex dev --once
```

The backend will be deployed to your Convex development instance. The app will connect automatically.

### 2. Generate the build server index

```bash
make refresh-lsp
```

### 3. Start the iOS Simulator on your Mac

- Open the Simulator app, or run:
  ```bash
  open -a Simulator
  # or
  xcrun simctl boot "iPhone 16"
  ```

### 4. Build, install, and launch the app on the Simulator

```bash
make run
```

The app will show a green "Convex: Connected" indicator when the backend connection is established.

## Other useful commands

- Build only:
  ```bash
  make build
  ```
- Run tests:
  ```bash
  make test
  ```
- Clean build artifacts:
  ```bash
  make clean
  ```

## Backend Development

When making changes to the Convex backend:

```bash
# Deploy schema/function changes
npx convex dev --once

# Start continuous development mode (watches for changes)
npx convex dev
```

**Important**: Run `npx convex dev --once` after modifying:
- `convex/schema.ts` (database schema)
- `convex/*.ts` (backend functions)

## Configuration (UPS APIs)

If you plan to call UPS APIs, set credentials in [Config.xcconfig](file:///Users/brettsmith/Developer/ios/sc-2/Config.xcconfig). An example is provided at [Config.xcconfig.example](file:///Users/brettsmith/Developer/ios/sc-2/Config.xcconfig.example).

Required keys:

- `UPS_CLIENT_ID=<YOUR_CLIENT_ID>`
- `UPS_CLIENT_SECRET=<YOUR_CLIENT_SECRET>`
- `UPS_ACCOUNT_NUMBER=<YOUR_ACCOUNT_NUMBER>`
- `UPS_API_BASE_URL=https://wwwcie.ups.com`
- `UPS_OAUTH_BASE_URL=https://wwwcie.ups.com`

## Notes

- Defaults to the "iPhone 16" simulator. If yours differs, change `SIM_NAME` in the [Makefile](file:///Users/brettsmith/Developer/ios/sc-2/Makefile).
- For deeper details, see [AGENT.md](file:///Users/brettsmith/Developer/ios/sc-2/AGENT.md).
