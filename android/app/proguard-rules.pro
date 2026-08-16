# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# DartSSH2 (if it has native components) / Networking / Models
-keep class com.bhoomi.ecogrid_intelligence.** { *; }

# Preserve Google Maps plugins
-keep class com.google.android.gms.maps.** { *; }

# TTS & Speech
-keep class com.tundralabs.fluttertts.** { *; }
-keep class com.csdcorp.speech_to_text.** { *; }

# Webview
-keep class io.flutter.plugins.webviewflutter.** { *; }

# Preserve classes with @Keep
-keep @androidx.annotation.Keep class * {*;}
-keepclassmembers class * {
    @androidx.annotation.Keep *;
}

# Ignore missing Play Core classes (Flutter dynamic feature delivery)
-dontwarn com.google.android.play.core.**
