#Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-keep public class * extends java.lang.Exception  # Optional: Keep custom exceptions.

# In an attempt to fix the app crashing in release mode when clicking into a text box
# https://github.com/flutter/flutter/issues/66232
# https://github.com/flutter/flutter/issues/72185
-keep class io.flutter.plugin.editing.** { *; }
