#!/bin/bash

echo "🚀 Building QuikAppCert for macOS..."

# Function to check if CocoaPods is working
check_cocoapods() {
    if ! pod --version > /dev/null 2>&1; then
        echo "❌ CocoaPods is not working properly"
        echo "🔧 Attempting to fix CocoaPods..."
        
        # Try to install/reinstall CocoaPods
        if command -v gem > /dev/null 2>&1; then
            echo "📦 Installing CocoaPods via gem..."
            sudo gem install cocoapods
        else
            echo "❌ Ruby gem not found. Please install Ruby first."
            exit 1
        fi
    else
        echo "✅ CocoaPods is working"
    fi
}

# Function to setup iOS/macOS dependencies
setup_dependencies() {
    echo "🔧 Setting up iOS/macOS dependencies..."
    
    # Check if we're in the right directory
    if [ ! -f "ios/Podfile" ] && [ ! -f "macos/Podfile" ]; then
        echo "⚠️  No Podfile found. This might be a desktop-only app."
        return 0
    fi
    
    # Try to install pods for iOS if it exists
    if [ -f "ios/Podfile" ]; then
        echo "📱 Installing iOS pods..."
        cd ios && pod install && cd ..
    fi
    
    # Try to install pods for macOS if it exists
    if [ -f "macos/Podfile" ]; then
        echo "🖥️  Installing macOS pods..."
        cd macos && pod install && cd ..
    fi
}

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean

# Get dependencies
echo "📦 Getting Flutter dependencies..."
flutter pub get

# Check CocoaPods
check_cocoapods

# Setup dependencies
setup_dependencies

# Build for macOS
echo "🔨 Building macOS app..."
flutter build macos

# Check if build was successful
if [ $? -eq 0 ]; then
    echo "✅ Build successful!"
    echo "📁 App location: build/macos/Build/Products/Release/quikappcert.app"
    
    # List the build products
    echo "📋 Build products:"
    find build/macos/Build/Products -name "*.app" 2>/dev/null || echo "No .app files found"
    
    # Check if the app was actually created
    if [ -d "build/macos/Build/Products/Release/quikappcert.app" ]; then
        echo "🎉 QuikAppCert.app successfully created!"
        echo "📍 Location: $(pwd)/build/macos/Build/Products/Release/quikappcert.app"
        echo "🚀 You can now run the app or distribute it!"
    else
        echo "⚠️  App bundle not found in expected location"
    fi
else
    echo "❌ Build failed!"
    echo "🔍 Check the error messages above for details"
    exit 1
fi 