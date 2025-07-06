# 🔧 CocoaPods Fix Guide for QuikAppCert

## The Issue

Your system has Ruby 2.6.10, but the latest CocoaPods requires Ruby 3.1.0+. This is a common issue on macOS.

## Solution Options

### Option 1: Install Compatible CocoaPods Version (Recommended)

```bash
# Remove any existing CocoaPods
sudo gem uninstall cocoapods

# Install a compatible version
sudo gem install cocoapods -v 1.11.3

# Verify installation
pod --version
```

### Option 2: Use Homebrew (Alternative)

```bash
# Install CocoaPods via Homebrew
brew install cocoapods

# Verify installation
pod --version
```

### Option 3: Update Ruby (Advanced)

```bash
# Install rbenv
brew install rbenv

# Install newer Ruby
rbenv install 3.2.0
rbenv global 3.2.0

# Install CocoaPods
gem install cocoapods
```

## Quick Build Commands

After fixing CocoaPods, run these commands:

```bash
# Clean and get dependencies
flutter clean
flutter pub get

# Install pods
cd macos && pod install && cd ..

# Build the app
flutter build macos
```

## Alternative: Build Without CocoaPods

If you can't fix CocoaPods, try building without it:

```bash
# Clean and get dependencies
flutter clean
flutter pub get

# Try building without CocoaPods
flutter build macos --no-tree-shake-icons
```

## Verification

After successful build, check:

```bash
# Check if app was created
ls -la build/macos/Build/Products/Release/

# Run the app
open build/macos/Build/Products/Release/quikappcert.app
```

## Troubleshooting

### If build still fails:

1. Check Flutter doctor: `flutter doctor -v`
2. Update Flutter: `flutter upgrade`
3. Accept Xcode license: `sudo xcodebuild -license accept`
4. Install command line tools: `xcode-select --install`

### If CocoaPods still doesn't work:

1. Try the Homebrew method above
2. Check Ruby version: `ruby --version`
3. Consider using rbenv to manage Ruby versions

## Success Indicators

✅ CocoaPods working: `pod --version` shows a version number  
✅ Build successful: `flutter build macos` completes without errors  
✅ App created: `quikappcert.app` exists in build directory  
✅ App runs: Double-click the .app file or use `open` command
