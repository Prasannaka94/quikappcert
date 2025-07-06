# 🍏 QuikAppCert — Apple Certificate & Profile Generator

A cross-platform Flutter tool to help users interact with the Apple Developer Portal for certificate generation and provisioning profile management.

## 🎯 Core Features

### 1️⃣ Generate Apple Distribution Certificate (.p12)

- **CSR Generation**: Create Certificate Signing Requests with custom details
- **Certificate Conversion**: Convert Apple Distribution .cer files to .p12 format
- **Cross-Platform Support**: Works on macOS (Keychain) and Windows/Linux (OpenSSL)
- **Default Password**: Uses `quikappcert` as default password (customizable)

### 2️⃣ Download Provisioning Profile (.mobileprovision)

- **Bundle ID Selection**: Choose your app's bundle identifier
- **Profile Types**: Support for App Store, Ad Hoc, and Development profiles
- **Latest Profiles**: Automatically fetches the most recent matching profile
- **Direct Download**: Saves profiles directly to your output directory

## 🖥️ Platform Support

| Feature                | macOS (GUI)   | Windows/Linux (CLI) |
| ---------------------- | ------------- | ------------------- |
| Certificate Generation | ✅            | ✅                  |
| .p12 Export            | ✅ (Keychain) | ✅ (OpenSSL)        |
| Provisioning Download  | ✅            | ✅                  |
| File History           | ✅            | ✅                  |
| Settings Management    | ✅            | ✅                  |

## 🔐 Requirements

- **Apple ID** with App-Specific Password
- **Valid Apple Developer Account**
- **Registered App ID / Bundle ID**
- **OpenSSL** (for Windows/Linux certificate operations)

## 🚀 Installation

### Prerequisites

1. **Flutter SDK** (3.8.1 or higher)
2. **Dart SDK** (3.8.1 or higher)
3. **OpenSSL** (for Windows/Linux users)

### Setup

```bash
# Clone the repository
git clone https://github.com/yourusername/quikappcert.git
cd quikappcert

# Install dependencies
flutter pub get

# Run the app
flutter run
```

## 📱 App Flow

### 🔑 Apple Login

1. Launch QuikAppCert
2. Sign in with your Apple ID and app-specific password
3. Generate an app-specific password at [appleid.apple.com](https://appleid.apple.com)

### 1️⃣ Generate Certificate (.p12)

#### Step 1: Create CSR

1. Navigate to "Generate Certificate"
2. Fill in certificate details:
   - Common Name (CN)
   - Organization (O)
   - Organizational Unit (OU)
   - Country (C)
   - State (ST)
   - Locality (L)
3. Click "Generate CSR"
4. Copy the generated CSR content

#### Step 2: Upload to Apple Developer Portal

1. Go to [Apple Developer Portal](https://developer.apple.com)
2. Navigate to Certificates → +
3. Upload the generated CSR
4. Download the .cer file

#### Step 3: Export as .p12

1. Back in QuikAppCert, click "Select .cer"
2. Choose your downloaded .cer file
3. (Optional) Customize .p12 password
4. Click "Export as .p12"
5. File saved to `~/Documents/QuikAppCert/`

### 2️⃣ Download Provisioning Profile (.mobileprovision)

1. Navigate to "Download Profile"
2. Enter your Bundle ID (e.g., `com.example.app`)
3. Select Profile Type (App Store, Ad Hoc, Development)
4. Click "Download Profile"
5. File saved to `~/Documents/QuikAppCert/`

## ⚙️ Advanced Features

### Settings

- **Default Output Directory**: Customize where files are saved
- **Auto-open Files**: Automatically open Finder/Explorer after generation
- **Copy Path to Clipboard**: Auto-copy file paths
- **Show Advanced Options**: Expand advanced settings by default
- **File History**: Track and manage generated files

### File History

- **Recent Files**: View last 3 generated files on home screen
- **Full History**: Access complete file history with filtering
- **File Actions**: Open, copy path, remove from history
- **File Status**: Shows if files still exist on disk

### Advanced Options

- **Custom .p12 Password**: Override default password
- **OpenSSL Logs**: View command execution details
- **API Logs**: See Apple Developer API responses
- **Custom Output Directory**: Override default location

## 📂 File Management

### Default Locations

- **macOS**: `~/Documents/QuikAppCert/`
- **Windows**: `C:\Users\<You>\Documents\QuikAppCert\`
- **Linux**: `~/Documents/QuikAppCert/`

### Generated Files

- **Certificates**: `apple_distribution.p12`
- **Profiles**: `<bundle_id>_<profile_type>.mobileprovision`
- **Private Keys**: `private.key`
- **CSR Files**: `cert.csr`

## 🔧 Development

### Project Structure

```
lib/
├── main.dart                 # App entry point
├── screens/                  # UI screens
│   ├── home_screen.dart      # Main dashboard
│   ├── certificate_screen.dart
│   ├── provisioning_profile_screen.dart
│   ├── settings_screen.dart
│   └── file_history_screen.dart
├── services/                 # Business logic
│   ├── apple_developer_service.dart
│   ├── certificate_service.dart
│   ├── file_history_service.dart
│   └── settings_service.dart
└── widgets/                  # Reusable components
    ├── action_card.dart
    └── apple_login_widget.dart
```

### Key Dependencies

- `http`: Apple Developer API communication
- `file_picker`: File selection dialogs
- `path_provider`: Cross-platform file paths
- `shared_preferences`: Settings persistence
- `process_run`: OpenSSL command execution

## 🛠️ Troubleshooting

### Common Issues

#### OpenSSL Not Found

```bash
# macOS
brew install openssl

# Ubuntu/Debian
sudo apt-get install openssl

# Windows
# Download from https://slproweb.com/products/Win32OpenSSL.html
```

#### Apple Login Issues

1. Ensure you're using an app-specific password
2. Verify your Apple Developer account is active
3. Check network connectivity

#### File Permission Errors

1. Ensure output directory is writable
2. Check disk space availability
3. Verify file paths don't contain special characters

## 📄 License

MIT License - Free to use, fork, or integrate into your pipeline.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/yourusername/quikappcert/issues)
- **Documentation**: [Wiki](https://github.com/yourusername/quikappcert/wiki)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/quikappcert/discussions)

---

**Made with ❤️ for the Apple Developer community**
