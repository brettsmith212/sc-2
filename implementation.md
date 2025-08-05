# Implementation Plan

## Configuration & Secrets

- [ ] Step 2: Externalize UPS credentials and endpoints
  - **Task**: Create a secure configuration model that loads the **Client ID**, **Client Secret**, optional **Merchant ID**, and environment-specific URLs at run-time.
  - **Description**: Keeps credentials out of source control and lets the human integrator supply them without re-compiling.
  - **Files**:
    - `Config/Secrets.plist.example`: property-list template with keys `UPS_CLIENT_ID`, `UPS_CLIENT_SECRET`, `UPS_MERCHANT_ID`, `UPS_OAUTH_BASE_URL`, `UPS_API_BASE_URL`
    - `Sources/Secrets.swift`: lightweight loader that reads the plist into memory, throws if any key is missing
  - **Step Dependencies**: Step 1
  - **Agent Instructions**:
    1. Generate `.example` file with placeholder values (`"<FILL-ME>"`).
    2. Add `Config/Secrets.plist` to `.gitignore`.
    3. In `Secrets.swift`, expose `public struct Secrets { let clientID: String; let clientSecret: String; let merchantID: String?; let oauthBaseURL: String; let apiBaseURL: String }`.
    4. Include both OAuth base URL (security endpoint) and API base URL (main endpoints) separately.

## Networking Layer

- [ ] Step 3: Foundation HTTP helpers
  - **Task**: Implement a tiny `HTTPClient` wrapper using `URLSession` and `async/await`.
  - **Description**: Centralizes all networking (headers, status-code checks, JSON (de)serialization) to avoid duplication.
  - **Files**:
    - `Sources/Networking/HTTPClient.swift`: generic `request()` that returns `(Data, HTTPURLResponse)`
  - **Step Dependencies**: Step 1
  - **Agent Instructions**:
    - Include exponential-backoff retry stub (configurable).
    - Accept `additionalHeaders: [String:String]` per call.

## OAuth Token Management

- [ ] Step 4: Build `UPSOAuthService`
  - **Task**: Exchange the **Client-Credentials** grant for a bearer token and cache it until `expires_in` – 60 s.
  - **Description**: Ensures every UPS API call has a valid `Authorization: Bearer …` header without prompting the user.
  - **Files**:
    - `Sources/Services/UPSOAuthService.swift`
  - **Step Dependencies**: Steps 2, 3
  - **Agent Instructions**:
    1. Read secrets via `Secrets`.
    2. POST to `{oauthBaseURL}/security/v1/oauth/token` with `grant_type=client_credentials`.
    3. Encode `clientID:clientSecret` using Base64 and set `Authorization: Basic …`.
    4. Set headers: `Content-Type: application/x-www-form-urlencoded`, `Accept: application/json`.
    5. URL-encode the body with `grant_type=client_credentials`.
    6. Optionally forward `x-merchant-id` if available.
    7. Store `{access_token, expires_at}` in memory; refresh automatically when `< 60 s` remain.
    8. Add concurrency protection to prevent multiple refresh requests.
    9. Implement 401 recovery: retry once with fresh token if API call returns 401.
    10. Consider persisting token in Keychain for offline app launches.
    11. Throw descriptive `UPSError` (enum) on non-200 HTTP codes.

## Address Validation API

- [ ] Step 5: Implement `UPSAddressValidationService`
  - **Task**: Provide a Swift function `validate(address:requestOption:)` that returns the UPS XAV response model.
  - **Description**: Proof-of-concept business feature the stakeholder will demo.
  - **Files**:
    - `Sources/Models/UPSAddressValidationModels.swift`: Codable structs for request/response with proper error handling
    - `Sources/Services/UPSAddressValidationService.swift`
  - **Step Dependencies**: Steps 3, 4
  - **Agent Instructions**:
    1. Accept parameter struct containing `street`, `city`, `state`, `postalCode`, `countryCode`.
    2. Add `requestOption` enum: `.validation(1)`, `.classification(2)`, `.both(3)`.
    3. Support optional query parameters: `regionalrequestindicator`, `maximumcandidatelistsize`.
    4. Craft JSON body per v2 spec with `XAVRequest` wrapper containing `AddressKeyFormat`.
    5. POST to `{apiBaseURL}/api/addressvalidation/v2/{requestOption}`.
    6. Headers: `Authorization: Bearer <token>`, `transId: UUID().uuidString` (max 32 chars), `transactionSrc: iOSDemo`, `Content-Type: application/json`, `Accept: application/json`.
    7. Return `Result<XAVResponse, UPSError>` to surface validation error codes (100910, 120002, 160002).
    8. Handle UPS error wrapper: `{ "response": { "errors": [...] } }`.
    9. Code defensively for Candidate array in v2 responses.

## Demo UI & Integration

- [ ] Step 6: Build minimal SwiftUI screen
  - **Task**: Form with address fields, “Validate” button, and JSON response viewer.
  - **Description**: Lets stakeholders manually test addresses inside the app.
  - **Files**:
    - `Sources/UI/AddressValidationView.swift`
  - **Step Dependencies**: Steps 1, 5
  - **Agent Instructions**:
    - Use `@State` for input fields.
    - Call `UPSAddressValidationService.validate` inside `Task {}`.
    - Display success JSON or error text in a scrollable `TextEditor`.

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
