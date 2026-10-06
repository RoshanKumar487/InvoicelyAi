# Invoicely Flutter client

This is the cross-platform Flutter replacement client, kept separate from the
existing Kotlin Android app and Spring Boot backend while features are migrated.
The migrated client includes sign-in, company and employee registration,
password reset, session restoration, responsive dashboards, invoice/client/
expense workflows, AI chat, reports, team management, templates, business and
invoice settings, and a tax calculator. The Kotlin app remains unchanged as a
reference during migration.

## Requirements

- Flutter 3.27 or newer (Dart 3.6 or newer)
- Android Studio / Android SDK for Android builds
- Xcode on macOS for iOS builds

## Run on Android

From this directory:

```powershell
flutter pub get
flutter run -d <android-device>
```

The default backend URL is `https://invoicelyai.onrender.com/`. To use another
environment, pass a URL ending in `/` or without the trailing slash:

```powershell
flutter run -d <android-device> --dart-define=API_BASE_URL=https://api.example.com/
```

Android development against a backend on the host machine should use
`http://10.0.2.2:8080/` from the Android emulator. Physical devices need the
host's LAN address and an appropriately configured backend.

The source uses Flutter's shared widget and data layers across Android, iOS,
and web. Android and iOS runners are included; iOS builds require macOS and
Xcode. Web deployments must allow the exact deployed web origin in the backend
CORS configuration.

## Migration status

Invoice PDF printing/sharing and DOCX export, editable speech-to-text input,
account-scoped secure AI chat history, and local invoice template/display
preferences are implemented in Flutter. Authenticated GET responses are cached
securely on-device and may be shown after network failures; HTTP/authentication
errors never fall back to stale cache. Refresh controls request current data
from the existing REST API. Mutations are not queued offline, and this client
does not connect directly to the database or add a custom Kotlin method
channel.

The dashboard presents role-scoped invoice health and revenue/spending
analytics. Reports provides searchable invoice, expense, and client grids with
date-range, invoice-status, and creator filters, plus multi-sheet Excel and PDF
exports of the filtered data.

Receipt scanning uses the platform image picker and the existing backend scan
endpoint. Speech recognition requires microphone/speech permissions, and iOS
builds and web speech behavior still need verification on their respective
platforms. Run `flutter analyze`, `flutter test`, and an Android build before
shipping; iOS builds must be validated on macOS with Xcode.
