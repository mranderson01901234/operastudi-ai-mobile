#!/bin/bash

# Flutter Android Environment Setup Script
# This script configures the Android development environment for Flutter

echo "🔧 Setting up Android development environment..."

# Set Android SDK Root
export ANDROID_SDK_ROOT=/home/mranderson/Android/Sdk
export ANDROID_HOME=/home/mranderson/Android/Sdk

# Add Android tools to PATH
export PATH=$PATH:$ANDROID_SDK_ROOT/emulator:$ANDROID_SDK_ROOT/platform-tools:$ANDROID_SDK_ROOT/cmdline-tools/latest/bin

echo "✅ Android environment variables configured:"
echo "   ANDROID_SDK_ROOT: $ANDROID_SDK_ROOT"
echo "   ANDROID_HOME: $ANDROID_HOME"

# Check if Android SDK exists
if [ ! -d "$ANDROID_SDK_ROOT" ]; then
    echo "❌ ERROR: Android SDK not found at $ANDROID_SDK_ROOT"
    exit 1
fi

# Check disk space
echo ""
echo "💾 Checking disk space..."
AVAILABLE_SPACE=$(df /home/ | awk 'NR==2 {print $4}')
AVAILABLE_GB=$((AVAILABLE_SPACE / 1024 / 1024))

if [ $AVAILABLE_GB -lt 8 ]; then
    echo "⚠️  WARNING: Low disk space detected (${AVAILABLE_GB}GB available)"
    echo "   Android emulators require at least 8-10GB free space"
    echo "   Current space may be insufficient for emulator operation"
else
    echo "✅ Sufficient disk space available (${AVAILABLE_GB}GB)"
fi

echo ""
echo "🏥 Running Flutter Doctor..."
flutter doctor -v

echo ""
echo "📱 Available Android emulators:"
flutter emulators

echo ""
echo "🔗 Available devices:"
flutter devices

echo ""
echo "🎯 Environment setup complete!"
echo "   To use this environment in new terminals, run:"
echo "   source $(pwd)/setup_android_env.sh"
echo ""
echo "   To make permanent, add these lines to ~/.zshrc or ~/.bashrc:"
echo "   export ANDROID_SDK_ROOT=/home/mranderson/Android/Sdk"
echo "   export ANDROID_HOME=/home/mranderson/Android/Sdk"
echo "   export PATH=\$PATH:\$ANDROID_SDK_ROOT/emulator:\$ANDROID_SDK_ROOT/platform-tools:\$ANDROID_SDK_ROOT/cmdline-tools/latest/bin" 