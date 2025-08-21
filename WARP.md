# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Project Overview

This is a Flutter mobile application focused on mobile money security and fraud detection for Tanzania. The app provides a dashboard for security agents to monitor transactions, analyze fraud patterns, and generate security reports. It features Firebase authentication, Firestore database integration, and supports multiple platforms with special handling for unsupported platforms like Linux desktop.

## Common Development Commands

### Build and Run
```bash
# Run on connected device/emulator (debug mode)
flutter run

# Run in release mode
flutter run --release

# Build APK for Android
flutter build apk

# Build for web
flutter build web

# Run on specific device
flutter devices  # List available devices
flutter run -d <device-id>
```

### Testing
```bash
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage

# Run widget tests specifically
flutter test test/widget_test.dart

# Run tests in verbose mode
flutter test --verbose
```

### Code Quality and Analysis
```bash
# Analyze code for issues
flutter analyze

# Format all Dart files
flutter format .

# Check for outdated dependencies
flutter pub outdated

# Update dependencies
flutter pub upgrade
```

### Firebase and Development Setup
```bash
# Get/update dependencies
flutter pub get

# Clean build artifacts
flutter clean

# Install/reinstall dependencies after clean
flutter pub get

# Generate Firebase configuration (requires Firebase CLI)
flutterfire configure
```

## Architecture and Code Structure

### Application Theme
The app simulates a mobile money security system for Tanzania with:
- Swahili greetings in the UI (`Habari za asubuhi`, `Habari za mchana`, `Habari za jioni`)
- Tanzanian Shilling (TShs) currency display
- Focus on mobile money platforms (M-Pesa, Airtel Money, HaloPesa, Tigo Pesa)
- Security agent persona with fraud detection features

### Main Components

**Authentication Flow:**
- `lib/main.dart`: App entry point with Firebase initialization and LoginPage
- `lib/signup.dart`: User registration with Firestore user data storage
- Firebase Auth handles authentication with platform-specific fallbacks

**Core Application Pages:**
- `lib/home.dart`: Main dashboard with security stats, quick actions, and activity feed
- `lib/transactions.dart`: Financial transaction logging with income/expense tracking
- `lib/analytics.dart`: Data visualization with charts and financial insights
- `lib/notifications.dart`: Security alerts and notification management system
- `lib/reporting.dart`: Report generation with export capabilities
- `lib/settings.dart`: Basic settings and profile management

### Firebase Integration Pattern

The app uses a defensive Firebase integration approach:

```dart
bool get _isFirebaseSupported => kIsWeb || 
    defaultTargetPlatform == TargetPlatform.android || 
    defaultTargetPlatform == TargetPlatform.iOS;
```

This pattern is consistently used across components to:
- Enable full Firebase functionality on supported platforms (Web, Android, iOS)
- Gracefully degrade functionality on unsupported platforms (Linux, Windows, macOS)
- Show appropriate user messages when Firebase features are unavailable

### State Management
- Uses StatefulWidget with setState for local component state
- No external state management library (Redux, Provider, Riverpod, etc.)
- Direct Firebase Auth and Firestore integration in widgets

### Key Dependencies
- `firebase_core`: ^4.0.0 - Firebase SDK initialization
- `firebase_auth`: ^6.0.1 - User authentication
- `cloud_firestore`: ^6.0.0 - NoSQL database for user data
- `cupertino_icons`: ^1.0.8 - iOS-style icons

## Development Guidelines

### Firebase Configuration
The `lib/firebase_options.dart` file contains placeholder values that need to be configured:
- Obtain actual Firebase configuration from Firebase Console
- Use `flutterfire configure` to set up proper values
- Update placeholder values for web, Android, and iOS platforms

### Platform Considerations
- Test Firebase features only on supported platforms (Web, Android, iOS)
- Verify graceful degradation on Linux/Windows/macOS
- Use platform checks before calling Firebase APIs

### Testing Strategy
- The existing test suite uses outdated patterns (counter app template)
- Consider adding integration tests for Firebase authentication flows
- Add widget tests for key UI components and navigation
- Test offline functionality and error handling

### Code Style
- Follows Flutter/Dart conventions with `flutter_lints` package
- Consistent use of Material Design components
- Defensive programming patterns for cross-platform compatibility

## Potential Improvements
- Implement proper state management (Provider, Riverpod, or Bloc)
- Add proper error handling and offline support
- Implement proper chart library (fl_chart) instead of custom widgets
- Add unit tests for business logic components
- Consider adding proper models/entities instead of Map<String, dynamic>
- Add proper navigation structure (go_router or similar)
- Implement proper responsive design for different screen sizes
