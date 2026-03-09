# Remaining Null Safety Fixes

## Status
- ✅ Fixed: ~80 null safety issues
- 🔄 Remaining: ~250 errors (mostly in datastore.dart, models, and widgets)

## Quick Fix Commands

### 1. Run Dart Migration Tool (Automated)
```bash
cd /Users/ilan/.cursor/worktrees/nullpass-mobile/lmc
dart migrate --apply-changes
```

This will automatically add nullability annotations across the entire codebase.

### 2. Manual Fixes Needed

#### A. datastore.dart (~50 errors)
Common patterns:
```dart
// Change return types to nullable
Future<List<Secret>> → Future<List<Secret>?>
Future<Vault> → Future<Vault?>
Future<Device> → Future<Device?>

// Add null checks before using
if (result != null) { ... }
result ?? defaultValue

// Late initialization
late List<Secret> _secrets;
```

#### B. Model constructors
All models need:
```dart
// Change @required to required
Device({
  @required String id,  // OLD
  required String id,   // NEW
  String? nickname,     // nullable params
})
```

#### C. Common Fixes
```dart
// Deprecated colon syntax
{int param: 5}      // OLD
{int param = 5}     // NEW

// Null aware operators
object?.method()
list?.length ?? 0
value!  // only if certain it's non-null
```

## Files with Most Errors

1. **lib/services/datastore.dart** (~53 errors)
   - Database query return types
   - SecureStorage read operations
   - List/Map operations

2. **lib/models/** (many files)
   - Constructor parameters
   - fromMap factory constructors
   - Field initializations

3. **lib/screens/** (various)
   - Widget state fields
   - Callback function types

## Testing After Fixes

```bash
# 1. Check for compilation errors
flutter analyze

# 2. Build debug APK
flutter build apk --debug

# 3. Run on device
flutter run
```

## Current Build Status

**Android Build**: ✅ Gradle + AGP working  
**Dart Compilation**: ❌ 250+ null safety errors  
**Completion**: ~75%  

## Next Steps

1. Run `dart migrate` (recommended - fastest)
2. OR manually fix remaining files:
   - datastore.dart
   - All model fromMap constructors
   - Widget state classes

3. Test build after each major fix
4. Re-enable disabled plugins after build succeeds:
   - timeline_list (find alternative)
   - secure_screen_switcher (needs namespace fix)

## Notes

- Some APIs changed between packages (e.g., local_auth 1.x → 2.x)
- OneSignal v5 REST API needs separate implementation for device-to-device messaging
- FlutterSecureStorage returns `Future<String?>` (nullable)
- All database queries can return null

## Estimated Time
- With dart migrate tool: 10-15 minutes + testing
- Manual fixes: 2-3 hours

---

**Last Updated**: Build reaching Dart compilation, 250 null safety errors remaining
