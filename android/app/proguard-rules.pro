# Flutter project specific rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Workaround for plugins that might crash with R8
-dontwarn io.flutter.plugins.**
-dontwarn androidx.**
-keepattributes Signature
-keepattributes *Annotation*
