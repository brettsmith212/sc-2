# Implementation Plan

## Configuration & Secrets

- [x] Step 2: Externalize UPS credentials and endpoints
  - **Task**: Create a secure configuration model that loads the **Client ID**, **Client Secret**, optional **Merchant ID**, and environment-specific URLs at run-time using iOS industry standard Build Settings approach.
  - **Description**: Keeps credentials out of source control using .xcconfig files and Xcode build system integration. No manual Xcode configuration required.
  - **Files**:
    - `Config.xcconfig.example`: Configuration template with keys `UPS_CLIENT_ID`, `UPS_CLIENT_SECRET`, `UPS_MERCHANT_ID`, `UPS_OAUTH_BASE_URL`, `UPS_API_BASE_URL`
    - `Config.xcconfig`: Actual credentials file (gitignored)
    - `sc-2/Config.swift`: Configuration loader that reads from Bundle.main.infoDictionary
  - **Step Dependencies**: Step 1
  - **Implementation**:
    1. ✅ Created `Config.xcconfig.example` with placeholder values (`"<FILL-ME>"`).
    2. ✅ Added `Config.xcconfig` to `.gitignore`.
    3. ✅ Implemented `public struct Config { let clientID: String; let clientSecret: String; let merchantID: String?; let oauthBaseURL: String; let apiBaseURL: String }`.
    4. ✅ Uses iOS industry standard Build Settings integration - .xcconfig automatically populates build settings.
    5. ✅ Includes OAuth base URL (security endpoint) and API base URL (main endpoints) separately.
    6. ✅ Graceful handling of optional merchant ID.
    7. ✅ Comprehensive error messages for missing configuration.

## Networking Layer

- [x] Step 3: Foundation HTTP helpers
  - **Task**: Implement a tiny `HTTPClient` wrapper using `URLSession` and `async/await`.
  - **Description**: Centralizes all networking (headers, status-code checks, JSON (de)serialization) to avoid duplication.
  - **Files**:
    - `sc-2/Networking/HTTPClient.swift`: generic `request()` that returns `(Data, HTTPURLResponse)`
  - **Step Dependencies**: Step 1
  - **Implementation**:
    1. ✅ Created comprehensive `HTTPClient` class with modern async/await support.
    2. ✅ Implemented configurable exponential backoff retry with jitter.
    3. ✅ Added support for `additionalHeaders: [String:String]` per call.
    4. ✅ Included specialized methods for JSON (`requestJSON`) and form-encoded (`requestForm`) requests.
    5. ✅ Added proper error handling with `HTTPClientError` enum.
    6. ✅ Implemented Retry-After header support for 429 responses.
    7. ✅ Added response status helpers (`isSuccessful`, `isClientError`, `isServerError`).
    8. ✅ Included JSON decoding and pretty-printing utilities for debugging.

## OAuth Token Management

- [x] Step 4: Build `UPSOAuthService`
  - **Task**: Exchange the **Client-Credentials** grant for a bearer token and cache it until `expires_in` – 60 s.
  - **Description**: Ensures every UPS API call has a valid `Authorization: Bearer …` header without prompting the user.
  - **Files**:
    - `sc-2/Services/UPSOAuthService.swift`
    - `sc-2/Models/UPSError.swift`
  - **Step Dependencies**: Steps 2, 3
  - **Implementation**:
    1. ✅ Created comprehensive `UPSError` enum with detailed error types and recovery information.
    2. ✅ Implemented OAuth models (`UPSOAuthResponse`, `UPSToken`) with expiration tracking.
    3. ✅ Built `UPSOAuthService` with `@MainActor` concurrency protection.
    4. ✅ Reads credentials via `Config` struct from Step 2.
    5. ✅ POSTs to `{oauthBaseURL}/security/v1/oauth/token` with proper Basic Auth and form encoding.
    6. ✅ Automatically refreshes tokens when < 60s remain until expiration.
    7. ✅ Prevents multiple concurrent refresh requests with Task management.
    8. ✅ Implements 401 recovery with automatic token invalidation and retry.
    9. ✅ Provides authenticated request helpers (`authenticatedRequest`, `authenticatedJSONRequest`).
    10. ✅ Handles UPS error responses and maps HTTP errors to structured `UPSError` types.
    11. ✅ Includes debug utilities for token inspection in development builds.

## Address Validation API

- [x] Step 5: Implement `UPSAddressValidationService`
  - **Task**: Provide a Swift function `validate(address:requestOption:)` that returns the UPS XAV response model.
  - **Description**: Proof-of-concept business feature the stakeholder will demo.
  - **Files**:
    - `sc-2/Models/UPSAddressValidationModels.swift`: Codable structs for request/response with proper error handling
    - `sc-2/Services/UPSAddressValidationService.swift`
  - **Step Dependencies**: Steps 3, 4
  - **Implementation**:
    1. ✅ Created comprehensive request/response models with `UPSAddress`, `UPSRequestOption`, and `XAVResponse`.
    2. ✅ Implemented `UPSRequestOption` enum with `.validation(1)`, `.classification(2)`, `.both(3)`.
    3. ✅ Added support for optional query parameters: `regionalrequestindicator`, `maximumcandidatelistsize`.
    4. ✅ Built JSON request body per v2 spec with `XAVRequest` wrapper containing `AddressKeyFormat`.
    5. ✅ Configured POST to `{apiBaseURL}/api/addressvalidation/v2/{requestOption}` with proper URL building.
    6. ✅ Added all required headers: `Authorization: Bearer <token>`, `transId: UUID().uuidString` (max 32 chars), `transactionSrc: iOSDemo`, `Content-Type: application/json`, `Accept: application/json`.
    7. ✅ Returns `Result<XAVResponse, UPSError>` with specific error handling for validation codes (100910, 120002, 160002).
    8. ✅ Integrated with existing UPS error handling system from `UPSError.swift`.
    9. ✅ Includes defensive coding for Candidate array in v2 responses with proper optionals.
    10. ✅ Added convenience methods for common use cases and user-friendly error messages.
    11. ✅ Implemented debug helpers and sample address testing for development.
    12. ✅ Added comprehensive extensions for response interpretation (`isValid`, `isAmbiguous`, `formattedAddress`).

## Demo UI & Integration

- [x] Step 6: Build minimal SwiftUI screen
  - **Task**: Form with address fields, “Validate” button, and JSON response viewer.
  - **Description**: Lets stakeholders manually test addresses inside the app.
  - **Files**:
    - `sc-2/Views/AddressValidationView.swift`
  - **Step Dependencies**: Steps 1, 5
  - **Implementation**:
    1. ✅ Created comprehensive SwiftUI form with address input fields (street, city, state, postal code, country code).
    2. ✅ Implemented validation options picker for `.validation`, `.classification`, and `.both`.
    3. ✅ Added `@State` properties for all input fields and validation states.
    4. ✅ Integrated `UPSAddressValidationService.validate` call inside async `Task {}`.
    5. ✅ Built scrollable result display with formatted success/error responses.
    6. ✅ Added loading states, progress indicators, and form validation.
    7. ✅ Included sample address button for easy testing.
    8. ✅ Created user-friendly error messages and formatted JSON response display.
    9. ✅ Integrated with main `ContentView` using sheet presentation.
    10. ✅ Added comprehensive UI polish with proper styling and accessibility.

## Logging & Error Reporting

- [ ] Step 7: Centralized logger
  - **Task**: Add simple `Logger` utility writing to console with log-level filtering.
  - **Description**: Aids debugging network failures and OAuth renewals without Xcode breakpoints.
  - **Files**:
    - `Sources/Utils/Logger.swift`
  - **Step Dependencies**: Steps 3–5
  - **Agent Instructions**:
    - Provide `debug`, `info`, `error` static funcs.
    - Gate logs behind `#if DEBUG`.

## Verification

- [ ] Step 8: Unit tests for OAuth & Address Validation
  - **Task**: Mock `URLProtocol` to simulate UPS responses and assert correct parsing/refresh logic.
  - **Description**: Guarantees future refactors don’t break the token cache or request schema.
  - **Files**:
    - `Tests/UPSOAuthServiceTests.swift`
    - `Tests/UPSAddressValidationServiceTests.swift`
  - **Step Dependencies**: Steps 3–5
  - **Agent Instructions**:
    - Include success & error scenarios (401, 500, 429 with Retry-After).
    - Test 401 recovery: verify that first API call returns 401, triggers refresh, and retry succeeds.
    - Use dependency-injected `HTTPClient` with stubbed responses.
    - Test UPS error wrapper parsing and specific error code handling.

## Deployment Readiness

- [ ] Step 9: Switch to Production UPS endpoints
  - **Task**: Parameterize base URL (`wwwcie.ups.com` → `onlinetools.ups.com`) via build configuration.
  - **Description**: Separates test vs. live traffic, satisfying UPS production-go-live checklist.
  - **Files**:
    - `Config/Environment.swift`: enum `.cie` / `.prod` returning base URLs
  - **Step Dependencies**: Steps 2–7
  - **Agent Instructions**:
    - Add Xcode build setting `UPS_ENV` and read at runtime.
    - Default to `.cie` for Debug, `.prod` for Release.

## Documentation

- [ ] Step 10: Write `README.md`
  - **Task**: Explain prerequisites, how to supply credentials, run tests, and toggle environments.
  - **Description**: Allows any new developer (or CI agent) to reproduce the demo end-to-end.
  - **Files**:
    - `README.md`
  - **Step Dependencies**: All previous steps
  - **Agent Instructions**:
    - Include a “Getting Started” section with the Secrets plist instructions.
    - Document sample cURL calls that mirror the Swift services.
