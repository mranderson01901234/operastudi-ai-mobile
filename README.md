# Selfie Editor

An AI-powered mobile photo editing app designed specifically for social media users, especially those taking selfies. Built with Flutter and featuring a clean, dark interface inspired by Lightroom.

## Features

### Core Functionality
- 📸 **Front-facing Camera**: Default camera for selfies
- 🖼️ **Gallery Integration**: Easy image selection from device gallery
- ☁️ **Google Drive Support**: Import images from cloud storage (planned)
- 🤖 **AI Enhancement**: One-tap AI-powered photo enhancement using Replicate API
- 🎨 **Manual Editing**: Real-time preview with sliders and controls

### Editing Tools
- **Filters**: Vintage, B&W, Sepia, Dramatic, Portrait
- **Light**: Brightness and contrast adjustments
- **Color**: Saturation and warmth controls
- **Effects**: Advanced effects (coming soon)
- **Crop**: Image cropping tools (coming soon)

### UI/UX
- 🌙 **Dark Theme**: Professional dark interface inspired by Lightroom
- 📱 **Mobile-First**: Optimized for Android and iOS
- ⚡ **Real-time Preview**: See changes instantly
- 🎯 **One-tap Enhancement**: Prominent AI enhance button
- 📊 **Bottom Sheets**: Clean editing controls that don't obstruct the image

## Project Structure

```
lib/
├── main.dart                    # App entry point
├── constants/
│   └── app_theme.dart          # Dark theme configuration
├── models/                      # Data models (ready for future use)
├── screens/
│   ├── landing_screen.dart     # Upload options (Camera, Gallery, Drive)
│   └── editing_screen.dart     # Main editing interface
├── services/
│   ├── app_state.dart          # State management with Provider
│   ├── camera_service.dart     # Camera and gallery integration
│   └── replicate_service.dart  # AI enhancement API integration
├── widgets/
│   ├── upload_option_card.dart # Upload option UI component
│   ├── image_display.dart      # Full-screen image display
│   ├── editing_footer.dart    # Footer with categories and enhance button
│   └── editing_bottom_sheet.dart # Bottom sheet editing controls
└── utils/                      # Utility functions (ready for future use)
```

## Getting Started

### Prerequisites
- Flutter SDK (3.5.4 or higher)
- Dart SDK
- Android Studio / VS Code
- Android device or emulator for testing

### Installation

1. Clone the repository
2. Navigate to the project directory:
   ```bash
   cd selfie_editor
   ```

3. Install dependencies:
   ```bash
   flutter pub get
   ```

4. Run the app:
   ```bash
   flutter run
   ```

### Development Commands

```bash
# Get dependencies
flutter pub get

# Run the app
flutter run

# Run on specific device
flutter run -d <device_id>

# Build APK for Android
flutter build apk

# Build for release
flutter build apk --release

# Run tests
flutter test

# Analyze code
flutter analyze

# Format code
dart format .
```

## Configuration

### Replicate API Setup
To enable AI enhancement features:

1. Get your API token from [Replicate](https://replicate.com)
2. Update `lib/services/replicate_service.dart`:
   ```dart
   static const String _apiToken = 'YOUR_REPLICATE_API_TOKEN';
   ```

3. Uncomment the AI enhancement code in `editing_screen.dart`

### Permissions
The app requires the following permissions:
- Camera access
- Gallery access
- Storage access (for saving images)

## Architecture

### State Management
- **Provider**: Used for state management across the app
- **AppState**: Centralized state for image, editing parameters, and UI state

### Key Components
- **LandingScreen**: Three upload options with loading states
- **EditingScreen**: Full-screen image display with footer controls
- **EditingFooter**: Scrollable categories + prominent enhance button
- **EditingBottomSheet**: Category-specific editing controls

### Design Principles
- **Mobile-First**: Optimized for touch interactions
- **Real-time Preview**: All changes visible immediately
- **Clean Interface**: Dark theme with minimal distractions
- **One-tap Actions**: Prominent enhance button for AI processing

## Target Audience

- Social media users (especially Instagram, TikTok)
- Selfie enthusiasts
- Content creators
- Users who want quick, professional-looking photos

## Future Enhancements

- [ ] Google Drive integration
- [ ] More AI models and filters
- [ ] Social media sharing
- [ ] Batch processing
- [ ] Advanced cropping tools
- [ ] Text overlay
- [ ] Sticker support
- [ ] Video editing capabilities

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests and ensure code quality
5. Submit a pull request

## License

This project is licensed under the MIT License.
