#!/bin/bash

echo "🚀 Launching QuikAppCert..."

# Check if the app exists
APP_PATH="build/macos/Build/Products/Debug/quikappcert.app"

if [ -d "$APP_PATH" ]; then
    echo "✅ App found at: $APP_PATH"
    echo "🎯 Launching QuikAppCert..."
    
    # Launch the app
    open "$APP_PATH"
    
    echo "✅ QuikAppCert launched successfully!"
    echo ""
    echo "📋 App Features Available:"
    echo "   • Apple Developer Login"
    echo "   • Certificate Generation (CSR → .cer → .p12)"
    echo "   • 9 Certificate Types Supported"
    echo "   • Automated .cer Download"
    echo "   • Export All Files Package"
    echo "   • File History & Management"
    echo "   • Settings & Preferences"
    echo ""
    echo "🎉 Enjoy using QuikAppCert!"
else
    echo "❌ App not found at: $APP_PATH"
    echo "💡 Try running: flutter run -d macos"
fi 