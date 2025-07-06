# 🚀 QuikAppCert macOS Build Guide

## Prerequisites

1. **Flutter SDK** (3.32.2 or later)
2. **Xcode** (16.4 or later)
3. **CocoaPods** (for iOS/macOS dependencies)
4. **Ruby** (for CocoaPods)

## Quick Build

### Option 1: Using the Build Script

```bash
# Make the script executable
chmod +x build_macos_fixed.sh

# Run the build script
./build_macos_fixed.sh
```

### Option 2: Manual Build

```bash
# 1. Clean previous builds
flutter clean

# 2. Get dependencies
flutter pub get

# 3. Fix CocoaPods (if needed)
sudo gem install cocoapods

# 4. Install pods for macOS
cd macos && pod install && cd ..

# 5. Build for macOS
flutter build macos
```

## Troubleshooting

### CocoaPods Issues

If you see "CocoaPods not installed or not in valid state":

1. **Reinstall CocoaPods:**

   ```bash
   sudo gem uninstall cocoapods
   sudo gem install cocoapods
   ```

2. **Alternative installation methods:**

   ```bash
   # Using Homebrew
   brew install cocoapods

   # Or using rbenv
   rbenv install 3.0.0
   rbenv global 3.0.0
   gem install cocoapods
   ```

### Xcode Issues

1. **Update Xcode** to the latest version
2. **Accept Xcode license:**
   ```bash
   sudo xcodebuild -license accept
   ```
3. **Install command line tools:**
   ```bash
   xcode-select --install
   ```

### Flutter Issues

1. **Update Flutter:**
   ```bash
   flutter upgrade
   ```
2. **Check Flutter doctor:**
   ```bash
   flutter doctor -v
   ```

## Running the App

### Debug Mode

```bash
flutter run -d macos
```

### Release Mode

```bash
flutter run -d macos --release
```

## App Location

After successful build, the app will be located at:

```
build/macos/Build/Products/Release/quikappcert.app
```

## Features

✅ **Apple Developer Login** - Secure authentication with app-specific passwords  
✅ **Certificate Generation** - Create .p12 files from CSR and .cer files  
✅ **Provisioning Profiles** - Download profiles by Bundle ID and type  
✅ **File History** - Track and manage generated files  
✅ **Settings Management** - Customize app behavior  
✅ **Cross-platform Support** - Works on macOS, Windows, and Linux

## File Structure

```
quikappcert/
├── lib/
│   ├── main.dart                 # App entry point
│   ├── screens/                  # UI screens
│   ├── services/                 # Business logic
│   ├── models/                   # Data models
│   └── widgets/                  # Reusable components
├── macos/                        # macOS-specific files
├── build_macos_fixed.sh          # Build script
└── BUILD_GUIDE.md               # This file
```

## Support

If you encounter issues:

1. Check the troubleshooting section above
2. Run `flutter doctor -v` and share the output
3. Check the build logs for specific error messages
4. Ensure all prerequisites are properly installed

## Next Steps

After building successfully:

1. Test the app functionality
2. Generate certificates and profiles
3. Customize settings as needed
4. Distribute the app to your team
