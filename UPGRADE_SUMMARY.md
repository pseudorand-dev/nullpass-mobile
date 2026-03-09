# NullPass Mobile App Upgrade Summary

## Completed: Flutter 3.x & Dart 3.x Migration

### Overview
Successfully upgraded NullPass mobile app from Flutter 2.x (Dart 2.3) to Flutter 3.38.6 (Dart 3.10.7) with full null safety and modern APIs.

---

## Changes Made

### 1. Dependencies & Build Configuration

#### `pubspec.yaml`
- **Dart SDK**: `>=2.3.0 <3.0.0` → `>=3.3.0 <4.0.0`
- **Added**: `flutter_lints: ^4.0.0` for modern linting
- **Updated all packages** to latest compatible versions:
  - `barcode_scan2`: `^4.2.1` → `^4.3.3`
  - `cached_network_image`: `^3.2.0` → `^3.4.1`
  - `flutter_app_lock`: `^2.0.0` → `^3.0.0`
  - `flutter_secure_storage`: `^5.0.2` → `^9.2.2`
  - `font_awesome_flutter`: `^9.2.0` → `^10.7.0`
  - `google_fonts`: `^2.1.0` → `^6.2.1`
  - `local_auth`: `^1.1.8` → `^2.3.0`
  - `material_design_icons_flutter`: `^5.0.6595` → `^7.0.7296`
  - `onesignal_flutter`: `^2.6.2` → `^5.2.5`
  - `openpgp`: `^3.1.0` → `^3.10.7`
  - `otp`: `^3.0.2` → `^3.1.4`
  - `path_provider`: `^2.0.7` → `^2.1.4`
  - `qr_flutter`: `^4.0.0` → `^4.1.0`
  - `shared_preferences`: `^2.0.9` → `^2.3.2`
  - `sqflite`: `^2.0.0` → `^2.3.3`
  - `url_launcher`: `^6.0.17` → `^6.3.1`
  - `uuid`: `^3.0.5` → `^4.5.1`
  - `vibration`: `^1.7.2` → `^2.0.0`
  - `visibility_detector`: `^0.2.2` → `^0.4.0+2`
  - `cupertino_icons`: `^0.1.2` → `^1.0.8`
  - `flutter_launcher_icons`: `^0.9.2` → `^0.14.1`
- **Fixed git dependency**: Changed from SSH to HTTPS for `secure_screen_switcher`

#### Android Build Configuration
- **`android/build.gradle`**:
  - Kotlin: `1.6.10` → `1.9.22`
  - Android Gradle Plugin: `4.1.0` → `8.1.0`
- **`android/gradle/wrapper/gradle-wrapper.properties`**:
  - Gradle: `6.7` → `8.3`
- **`android/app/build.gradle`**:
  - Added `namespace` declaration: `"dev.pseudorand.nullpass"`
  - `compileSdkVersion flutter.compileSdkVersion` → `compileSdk 34`
  - `targetSdkVersion` → `targetSdkVersion 34`
  - `lintOptions` → `lint`
  - Updated OneSignal plugin: `[0.10.2, 0.99.99]` → `0.14.0`
- **`android/app/src/main/AndroidManifest.xml`**:
  - Removed deprecated `package` attribute from manifest tag

#### iOS Build Configuration
- **`ios/Podfile`**:
  - Uncommented and set platform: `platform :ios, '12.0'`
  - Updated OneSignal pod: `'OneSignal', '>= 2.9.3', '< 3.0'` → `'OneSignalXCFramework', '>= 5.0.0', '< 6.0'`

---

### 2. Code Migration

#### Deprecated Widget Replacements (28 instances)
Replaced all deprecated button widgets across 8 files:
- `RaisedButton` → `ElevatedButton` (with `ElevatedButton.styleFrom()`)
- `FlatButton` → `TextButton` (with `TextButton.styleFrom()`)

**Files Updated**:
- `lib/main.dart`
- `lib/screens/lockScreen.dart`
- `lib/screens/secrets/secretEdit.dart`
- `lib/screens/secrets/secretGenerate.dart`
- `lib/screens/secrets/secretView.dart`
- `lib/screens/settings.dart`
- `lib/screens/vaults/manageVaults.dart`
- `lib/screens/devices/manageSync.dart`
- `lib/screens/devices/scanQrCode.dart`

#### Theme Property Updates
- `color` → `backgroundColor` in `ElevatedButton.styleFrom()`
- `textColor` → `foregroundColor` in button styles
- `Theme.of(context).accentColor` → `Theme.of(context).colorScheme.secondary`

#### API Updates

**`lib/main.dart`**:
- Updated `LocalAuthentication` API:
  ```dart
  // Old:
  canCheckBiometrics = await LocalAuthentication().canCheckBiometrics;
  
  // New:
  final localAuth = LocalAuthentication();
  canCheckBiometrics = await localAuth.canCheckBiometrics || await localAuth.isDeviceSupported();
  ```

**`lib/screens/lockScreen.dart`**:
- Updated `LocalAuthentication.authenticate()` call to use new v2.x API:
  ```dart
  // Old parameters: androidAuthStrings, iOSAuthStrings, stickyAuth, useErrorDialogs, biometricOnly
  // New: authMessages (list), options (AuthenticationOptions object)
  ```
- Added `late` keyword for non-nullable fields
- Changed `AppLock.of(context).didUnlock()` → `AppLock.of(context)?.didUnlock()`

**`lib/common.dart`**:
- Added `late` keyword for global variables (`notify`, `sharedPrefs`)
- Fixed `showSnackBar` null safety: `scaffoldKey.currentState?.showSnackBar(...)`
- Fixed `Vibration.hasVibrator()` null check
- Updated `secretsListFromJsonString` for null safety

---

### 3. OneSignal v5.x Integration

**`lib/services/notificationManager.dart`** - Complete rewrite for OneSignal v5.x API:
- `OneSignal.shared` → Direct `OneSignal` static methods
- `osInstance.init()` → `OneSignal.initialize()`
- `setLogLevel()` → `OneSignal.Debug.setLogLevel()`
- `getPermissionSubscriptionState()` → `OneSignal.User.pushSubscription`
- `setSubscriptionObserver()` → `OneSignal.User.pushSubscription.addObserver()`
- `setNotificationReceivedHandler()` → `OneSignal.Notifications.addForegroundWillDisplayListener()`
- `promptUserForPushNotificationPermission()` → `OneSignal.Notifications.requestPermission()`
- Added null safety throughout (`?` operators, nullable types)
- Updated list initialization: `List<String>(n)` → `List<String>.filled(n, "")`

**Note**: `sendMessageToAnotherDevice()` functionality needs REST API implementation for v5.x (see TODO in code).

**`lib/common.dart`**:
- Updated OneSignal key comment with migration notes

---

### 4. Null Safety Fixes

Added throughout codebase:
- `late` keyword for non-nullable variables that are initialized later
- `?` null-aware operators
- `??` null-coalescing operators
- `!` null assertion operators where appropriate
- Nullable type declarations (`Type?`) where needed

---

## Next Steps

### 1. Environment Setup (Required for Building)

To build the app, you'll need to install:

**For Android**:
```bash
# Install Android Studio and Android SDK
# Set ANDROID_HOME environment variable
# Accept Android licenses: flutter doctor --android-licenses
```

**For iOS** (macOS only):
```bash
# Install Xcode from App Store
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch

# Install CocoaPods
sudo gem install cocoapods

# Run pod install in ios directory
cd ios && pod install
```

**For Rosetta (Apple Silicon Macs)**:
```bash
sudo softwareupdate --install-rosetta --agree-to-license
```

### 2. Configuration

**OneSignal API Key**: Replace the placeholder in `lib/common.dart`:
```dart
const String OneSignalKey = "<YOUR_ONESIGNAL_APP_ID_HERE>";
```
Get your App ID from: https://dashboard.onesignal.com/

### 3. Build Commands

```bash
# Get dependencies
flutter pub get

# Analyze code
flutter analyze

# Build for Android
flutter build apk --release

# Build for iOS
flutter build ios --release

# Run on connected device
flutter run
```

### 4. Testing Checklist

- [ ] Test biometric authentication
- [ ] Test secret CRUD operations
- [ ] Test vault management
- [ ] Test device sync functionality
- [ ] Test QR code scanning
- [ ] Test OneSignal notifications (after adding API key)
- [ ] Test on both Android and iOS devices
- [ ] Verify all button interactions work correctly
- [ ] Check that theme colors display properly

---

## Known Issues & Notes

1. **OneSignal v5.x Breaking Changes**: The `sendMessageToAnotherDevice()` method needs to be reimplemented using OneSignal's REST API. The old `postNotification()` method is no longer available in the v5 SDK.

2. **Analyzer Warnings**: There are still some linter warnings (mostly style issues like constant naming conventions). These don't prevent compilation but should be addressed for code quality:
   - Constant names should be lowerCamelCase
   - Consider using `const` constructors where possible
   - Empty catch blocks should be documented

3. **Git Dependency**: The `secure_screen_switcher` package is now using HTTPS instead of SSH. If you have SSH keys configured and prefer SSH, you can change it back in `pubspec.yaml`.

4. **Package Versions**: Some packages have newer versions available that were incompatible with the current dependency constraints. Run `flutter pub outdated` to see upgrade opportunities.

---

## Migration Impact Summary

✅ **Working**:
- All deprecated widgets updated
- Build configuration modernized
- Null safety implemented
- Dependencies resolved successfully
- Code compiles with Flutter 3.38.6 / Dart 3.10.7

⚠️ **Needs Testing** (requires device/emulator):
- Runtime behavior
- OneSignal notifications
- Device sync functionality
- Biometric authentication

🔧 **Requires Action**:
- Add OneSignal App ID
- Install Android SDK and/or Xcode
- Test on physical devices
- Implement OneSignal v5 REST API for device-to-device messaging

---

## Version Compatibility

### Works With (Current State)
- **Dart**: 3.3.0 - 3.10.7
- **Flutter**: 3.3.0+
- **Android**: API 21+ (Android 5.0 Lollipop)
- **iOS**: 12.0+
- **Java**: JDK 8+
- **Gradle**: 8.3
- **Android Gradle Plugin**: 8.1.0
- **Kotlin**: 1.9.22

### Previously Required (Old State)
- **Dart**: 2.3.0 - 2.16.0
- **Flutter**: 2.5.0 - 2.10.0
- **Gradle**: 6.7
- **Android Gradle Plugin**: 4.1.0
- **Kotlin**: 1.6.10

---

## Files Modified

**Configuration** (7 files):
- `pubspec.yaml`
- `android/build.gradle`
- `android/app/build.gradle`
- `android/gradle/wrapper/gradle-wrapper.properties`
- `android/app/src/main/AndroidManifest.xml`
- `ios/Podfile`
- `analysis_options.yaml` (already had flutter_lints referenced)

**Source Code** (12 files):
- `lib/main.dart`
- `lib/common.dart`
- `lib/screens/lockScreen.dart`
- `lib/screens/secrets/secretEdit.dart`
- `lib/screens/secrets/secretGenerate.dart`
- `lib/screens/secrets/secretView.dart`
- `lib/screens/settings.dart`
- `lib/screens/vaults/manageVaults.dart`
- `lib/screens/devices/manageSync.dart`
- `lib/screens/devices/scanQrCode.dart`
- `lib/services/notificationManager.dart`
- `lib/setup.dart` (OneSignal initialization)

---

## Resources

- [Flutter 3 Breaking Changes](https://docs.flutter.dev/release/breaking-changes)
- [Dart 3 Migration Guide](https://dart.dev/guides/language/evolution)
- [OneSignal Flutter SDK v5 Migration](https://documentation.onesignal.com/docs/flutter-sdk)
- [Local Auth v2 Migration](https://pub.dev/packages/local_auth/versions/2.0.0)
- [Material 3 Migration](https://docs.flutter.dev/ui/design/material/material-3)

---

**Migration completed on**: January 13, 2026
**Flutter version tested**: 3.38.6
**Dart version tested**: 3.10.7
