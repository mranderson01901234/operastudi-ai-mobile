#!/bin/bash

# Android Development Setup Script for Flutter Selfie Editor
# This script helps set up Android development environment for the Flutter app

echo "🚀 Setting up Android development environment for Flutter Selfie Editor..."

# Check if running on supported OS
if [[ "$OSTYPE" != "linux-gnu"* ]] && [[ "$OSTYPE" != "darwin"* ]]; then
    echo "❌ This script is designed for Linux/macOS. For Windows, please follow Flutter documentation."
    exit 1
fi

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check Java installation
echo "📋 Checking Java installation..."
if command_exists java; then
    java_version=$(java -version 2>&1 | head -n 1)
    echo "✅ Java found: $java_version"
else
    echo "❌ Java not found. Please install Java 8 or higher."
    echo "   Ubuntu/Debian: sudo apt-get install openjdk-11-jdk"
    echo "   macOS: brew install openjdk@11"
    exit 1
fi

# Check Flutter installation
echo "📋 Checking Flutter installation..."
if command_exists flutter; then
    flutter_version=$(flutter --version | head -n 1)
    echo "✅ Flutter found: $flutter_version"
else
    echo "❌ Flutter not found. Please install Flutter first."
    echo "   Visit: https://flutter.dev/docs/get-started/install"
    exit 1
fi

# Create Android SDK directory
ANDROID_HOME="$HOME/Android/Sdk"
echo "📁 Setting up Android SDK directory: $ANDROID_HOME"
mkdir -p "$ANDROID_HOME"

# Download Android command line tools if not exists
CMDLINE_TOOLS_DIR="$ANDROID_HOME/cmdline-tools"
if [ ! -d "$CMDLINE_TOOLS_DIR/latest" ]; then
    echo "⬇️ Downloading Android command line tools..."
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        CMDTOOLS_URL="https://dl.google.com/android/repository/commandlinetools-mac-9477386_latest.zip"
    else
        CMDTOOLS_URL="https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip"
    fi
    
    cd /tmp
    wget -O cmdline-tools.zip "$CMDTOOLS_URL"
    unzip -q cmdline-tools.zip
    mkdir -p "$CMDLINE_TOOLS_DIR"
    mv cmdline-tools "$CMDLINE_TOOLS_DIR/latest"
    rm cmdline-tools.zip
    cd -
    echo "✅ Android command line tools downloaded"
fi

# Set environment variables
echo "🔧 Setting up environment variables..."
export ANDROID_HOME="$HOME/Android/Sdk"
export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator"

# Add to shell profile
SHELL_PROFILE=""
if [ -n "$ZSH_VERSION" ]; then
    SHELL_PROFILE="$HOME/.zshrc"
elif [ -n "$BASH_VERSION" ]; then
    SHELL_PROFILE="$HOME/.bashrc"
fi

if [ -n "$SHELL_PROFILE" ]; then
    echo "📝 Adding environment variables to $SHELL_PROFILE"
    {
        echo ""
        echo "# Android SDK"
        echo "export ANDROID_HOME=\"\$HOME/Android/Sdk\""
        echo "export PATH=\"\$PATH:\$ANDROID_HOME/cmdline-tools/latest/bin:\$ANDROID_HOME/platform-tools:\$ANDROID_HOME/emulator\""
    } >> "$SHELL_PROFILE"
fi

# Accept Android licenses
echo "📜 Accepting Android licenses..."
yes | "$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" --licenses >/dev/null 2>&1

# Install required Android packages
echo "📦 Installing Android packages..."
"$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" \
    "platform-tools" \
    "platforms;android-34" \
    "build-tools;34.0.0" \
    "emulator" \
    "system-images;android-30;google_apis;x86_64"

# Create Android Virtual Device (AVD)
echo "📱 Creating Android Virtual Device..."
AVD_NAME="Flutter_Emulator"
echo "no" | "$ANDROID_HOME/cmdline-tools/latest/bin/avdmanager" create avd \
    -n "$AVD_NAME" \
    -k "system-images;android-30;google_apis;x86_64" \
    --device "pixel_4"

# Configure Flutter
echo "🔧 Configuring Flutter for Android development..."
flutter config --android-sdk "$ANDROID_HOME"

# Run Flutter doctor
echo "🏥 Running Flutter doctor..."
flutter doctor

echo ""
echo "✅ Android development setup completed!"
echo ""
echo "📝 Next steps:"
echo "   1. Restart your terminal or run: source $SHELL_PROFILE"
echo "   2. Start the emulator: flutter emulators --launch $AVD_NAME"
echo "   3. Run the app: flutter run"
echo ""
echo "🔧 Development commands:"
echo "   • List emulators: flutter emulators"
echo "   • Start emulator: flutter emulators --launch $AVD_NAME"
echo "   • List devices: flutter devices"
echo "   • Run app: flutter run"
echo "   • Hot reload: Press 'r' in the terminal while app is running"
echo "   • Debug mode: flutter run --debug"
echo ""
echo "🐛 Debugging features enabled:"
echo "   • Long press the bug icon (top-right) to open debug panel"
echo "   • View logs, performance stats, and system info"
echo "   • Camera will fallback to gallery in emulator"
echo "   • Image processing optimized for emulator performance"
