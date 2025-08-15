# sc-2 iOS App

SwiftUI app with UPS Address Validation and Rating examples.

## Prerequisites

- Xcode (with iOS Simulator)
- xcode-build-server (for IDE language features). Install via Homebrew:
  ```bash
  brew install xcode-build-server
  ```

## Getting started

1. Generate the build server index `buildServer.json`

```bash
make refresh-lsp
```

2. Start the iOS Simulator on your Mac

- Open the Simulator app, or run:
  ```bash
  open -a Simulator
  # or
  xcrun simctl boot "iPhone 16"
  ```

3. Build, install, and launch the app on the Simulator

```bash
make run
```

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
