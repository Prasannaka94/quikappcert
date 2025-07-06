#!/bin/bash

echo "🔧 Fixing CocoaPods..."

# Remove the broken pod executable
sudo rm -f /usr/local/bin/pod

# Install CocoaPods with system Ruby
sudo gem install cocoapods

# Verify installation
if pod --version > /dev/null 2>&1; then
    echo "✅ CocoaPods fixed successfully!"
    echo "📦 Installing pods for macOS..."
    cd macos && pod install && cd ..
    
    echo "🔨 Building macOS app..."
    flutter build macos
    
    if [ $? -eq 0 ]; then
        echo "🎉 Build successful!"
        echo "📁 App location: build/macos/Build/Products/Release/quikappcert.app"
    else
        echo "❌ Build failed!"
    fi
else
    echo "❌ Failed to fix CocoaPods"
    exit 1
fi 