# UPS API Setup Requirements

## What You Need to Provide

### 1. UPS Developer Account
- Create account at https://developer.ups.com/
- Navigate to "My Apps & Keys" section

### 2. Application Configuration
Create a new application with these entitlements:
- **"Address Validation – Street Level"** (required)
- **"OAuth Client Credentials"** (required)
- **"OAuth Authorization Code"** (optional, for future customer integrations)

### 3. Credentials to Collect
From your UPS app dashboard, collect:
- **Client ID** 
- **Client Secret**
- **6-digit UPS Account Number** (optional but recommended for x-merchant-id header)

### 4. Environment URLs
- **Testing (CIE):**
  - OAuth: `https://wwwcie.ups.com/`
  - API: `https://wwwcie.ups.com/`
- **Production:**
  - OAuth: `https://onlinetools.ups.com/`
  - API: `https://onlinetools.ups.com/`

### 5. Create Your Configuration File
Copy `Config.xcconfig.example` to `Config.xcconfig` and fill in your values:
```bash
# UPS API Configuration
UPS_CLIENT_ID = your_client_id_here
UPS_CLIENT_SECRET = your_client_secret_here
UPS_MERCHANT_ID = your_6_digit_account_number
UPS_OAUTH_BASE_URL = https:/$()/wwwcie.ups.com/
UPS_API_BASE_URL = https:/$()/wwwcie.ups.com/
```

### 6. Configure Xcode Project
1. In Xcode, select your project in the navigator
2. Select the **sc-2** target
3. Go to **Build Settings** tab
4. Search for "User-Defined"
5. Add the following User-Defined Settings:
   - `UPS_CLIENT_ID` = `$(UPS_CLIENT_ID)`
   - `UPS_CLIENT_SECRET` = `$(UPS_CLIENT_SECRET)`
   - `UPS_MERCHANT_ID` = `$(UPS_MERCHANT_ID)`
   - `UPS_OAUTH_BASE_URL` = `$(UPS_OAUTH_BASE_URL)`
   - `UPS_API_BASE_URL` = `$(UPS_API_BASE_URL)`

### 7. Update Info.plist
Add these keys to your Info.plist:
```xml
<key>UPS_CLIENT_ID</key>
<string>$(UPS_CLIENT_ID)</string>
<key>UPS_CLIENT_SECRET</key>
<string>$(UPS_CLIENT_SECRET)</string>
<key>UPS_MERCHANT_ID</key>
<string>$(UPS_MERCHANT_ID)</string>
<key>UPS_OAUTH_BASE_URL</key>
<string>$(UPS_OAUTH_BASE_URL)</string>
<key>UPS_API_BASE_URL</key>
<string>$(UPS_API_BASE_URL)</string>
```

## Important Notes

### Testing Limitations
- **Address Validation in CIE only works for New York (NY) and California (CA)**
- Other states will return "NoCandidatesIndicator" - this is expected behavior

### Production Go-Live
- Ensure your app status is "Production" in UPS portal before switching URLs
- UPS requires "certification" - keep cURL transcripts of successful API calls
- Update URLs to production endpoints when ready

### Security
- Never commit `Config.xcconfig` to version control
- The build system injects values at build time
- Consider using Keychain for token persistence
- Keep credentials secure and rotate them periodically
