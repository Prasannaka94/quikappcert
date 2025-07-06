#!/bin/bash

echo "🚀 Building QuikAppCert for macOS (Simple Mode)..."

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean

# Get dependencies
echo "📦 Getting Flutter dependencies..."
flutter pub get

# Try to build without CocoaPods first
echo "🔨 Attempting build without CocoaPods..."
flutter build macos --no-tree-shake-icons

# Check if build was successful
if [ $? -eq 0 ]; then
    echo "✅ Build successful without CocoaPods!"
    echo "📁 App location: build/macos/Build/Products/Release/quikappcert.app"
    
    # Check if the app was actually created
    if [ -d "build/macos/Build/Products/Release/quikappcert.app" ]; then
        echo "🎉 QuikAppCert.app successfully created!"
        echo "📍 Location: $(pwd)/build/macos/Build/Products/Release/quikappcert.app"
        echo "🚀 You can now run the app!"
        
        # Try to run the app
        echo "🔄 Testing the app..."
        open build/macos/Build/Products/Release/quikappcert.app
    else
        echo "⚠️  App bundle not found in expected location"
    fi
else
    echo "❌ Build failed without CocoaPods"
    echo "🔧 This might require CocoaPods. Please fix CocoaPods and try again."
    echo "💡 Try: sudo gem install cocoapods -v 1.12.1"
fi 