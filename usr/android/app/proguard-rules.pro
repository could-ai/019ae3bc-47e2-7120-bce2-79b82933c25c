# Flutter Wrapper Rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Sqflite
-keep class com.tekartik.sqflite.** { *; }

# Workmanager
-keep class dev.fluttercommunity.plus.workmanager.** { *; }

# Models
-keep class com.example.autoverify.models.** { *; }

# Retrofit/OkHttp/Gson (if used natively, but we use Dio in Dart)
# Dio uses reflection in some cases? No, but good to be safe.
