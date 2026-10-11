# Hiányzó Play Core osztályok miatti leállás megelőzése
-dontwarn com.google.android.play.core.**

# Általános figyelmeztetések átugrása
-dontwarn **

# Flutter és keretrendszer védelme
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Saját SOS osztályok és a Widget receiver megőrzése
-keep class com.example.sos_eltvedtem.** { *; }

# HomeWidget modul
-keep class es.antonborri.home_widget.** { *; }