# Proguard rules for Invoicely Flutter app
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
-dontwarn com.google.mlkit.**
-keep class com.google.mlkit.** { *; }
-dontwarn io.flutter.**
-keep class io.flutter.** { *; }
