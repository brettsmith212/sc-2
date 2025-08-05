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

### 5. Create Your Secrets File
Copy `Config/Secrets.plist.example` to `Config/Secrets.plist` and fill in:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>UPS_CLIENT_ID</key>
    <string>your_client_id_here</string>
    <key>UPS_CLIENT_SECRET</key>
    <string>your_client_secret_here</string>
    <key>UPS_MERCHANT_ID</key>
    <string>your_6_digit_account_number</string>
    <key>UPS_OAUTH_BASE_URL</key>
    <string>https://wwwcie.ups.com/</string>
    <key>UPS_API_BASE_URL</key>
    <string>https://wwwcie.ups.com/</string>
</dict>
</plist>
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
- Never commit `Config/Secrets.plist` to version control
- Consider using Keychain for token persistence
- Keep credentials secure and rotate them periodically
