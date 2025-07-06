#!/bin/bash

echo "🚀 Building QuikAppCert for macOS..."

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean

# Get dependencies
echo "📦 Getting dependencies..."
flutter pub get

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
else
    echo "❌ Build failed!"
    exit 1
fi 