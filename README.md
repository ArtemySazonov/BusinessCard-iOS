# BusinessCard Wallet Pass Generator

This repo contains:

- **BusinessCardWallet**: iOS/iPadOS SwiftUI app that builds a pass bundle locally and sends it to a local signer service.
- **signer_service**: Minimal FastAPI signing service that runs on your Mac and returns a signed `.pkpass`.

## Project Structure

```
BusinessCard-iOS/
├─ BusinessCardWallet/
│  ├─ BusinessCardWallet.xcodeproj/
│  ├─ BusinessCardWallet/
│  │  ├─ Models/
│  │  ├─ Services/
│  │  ├─ ViewModels/
│  │  ├─ Views/
│  │  ├─ Assets.xcassets/
│  │  └─ Info.plist
│  └─ BusinessCardWalletTests/
└─ signer_service/
   ├─ app/
   ├─ tests/
   ├─ Dockerfile
   └─ requirements.txt
```

## iOS App Overview

Pass style: **Generic** (matches a business-card style layout with primary/secondary fields).

- SwiftUI + SwiftData, iOS/iPadOS 17+.
- NavigationSplitView on iPad, adaptive NavigationStack on iPhone.
- MVVM-style organization with services for vCard, QR, payload build, and signer networking.
- Builds a Wallet-style preview and generates pass assets locally (no signing on device).
- Calls the signer service to get a `.pkpass` and presents `PKAddPassesViewController`.

### Settings

In the in-app Settings sheet, set:

- **Signer Base URL** (e.g., `http://192.168.1.2:8080`)
- **Pass Type Identifier**
- **Team Identifier**
- **Organization Name**
- **Description**

Use **Connection Test** to hit `GET /health`.

## Signer Service Setup (Option A)

### Requirements

- macOS with OpenSSL installed (`brew install openssl` if needed)
- Pass Type ID certificate exported as `.p12`
- Apple WWDR intermediate certificate

### Certificate Prep

1. Create a Pass Type ID in the Apple Developer portal.
2. Create/download the certificate.
3. Export as `.p12` with a password.
4. Download WWDR certificate from Apple’s developer site.

### Environment Variables

Set these before running the signer:

- `PASS_CERT_P12_PATH`
- `PASS_CERT_P12_PASSWORD`
- `WWDR_CERT_PATH`
- `PASS_TYPE_IDENTIFIER`
- `TEAM_IDENTIFIER`
- `ORGANIZATION_NAME` (optional default)

### Run Locally (Python)

```bash
cd signer_service
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --host 0.0.0.0 --port 8080
```

### Run with Docker

```bash
docker build -t pass-signer .
docker run --rm -p 8080:8080 \
  -e PASS_CERT_P12_PATH=/certs/pass.p12 \
  -e PASS_CERT_P12_PASSWORD=your_password \
  -e WWDR_CERT_PATH=/certs/wwdr.pem \
  -e PASS_TYPE_IDENTIFIER=pass.com.example.businesscard \
  -e TEAM_IDENTIFIER=TEAMID1234 \
  -v /path/to/certs:/certs \
  pass-signer
```

### Signer API

- `GET /health` → `{ "status": "ok", "version": "1.0.0" }`
- `POST /sign-pass`
  - **JSON** body:
    ```json
    {
      "passJson": "<base64>",
      "files": [
        { "name": "icon.png", "data": "<base64>" },
        { "name": "thumbnail.png", "data": "<base64>" }
      ]
    }
    ```
  - **Multipart**: `pass.json` + any image files.

## Add to Wallet Troubleshooting

- **Signer not reachable**: verify device and Mac are on same LAN and Base URL is correct.
- **passTypeIdentifier/teamIdentifier mismatch**: check Settings vs signer env.
- **Invalid pass**: ensure WWDR cert is correct and the `.p12` matches your Pass Type ID.
- **HTTP**: acceptable for LAN dev; for HTTPS, put a reverse proxy in front of the signer.

## Tests

### iOS Unit Tests

Run in Xcode or:

```bash
xcodebuild -project BusinessCardWallet/BusinessCardWallet.xcodeproj -scheme BusinessCardWallet -destination 'platform=iOS Simulator,name=iPhone 15' test
```

### Signer Service Unit Test

```bash
cd signer_service
pytest
```
