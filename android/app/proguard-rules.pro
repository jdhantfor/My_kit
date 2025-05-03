# Правила для Gson, используемого flutter_local_notifications
-keep class com.google.gson.** { *; }
-keep interface com.google.gson.** { *; }
-dontwarn com.google.gson.**

# Правила для flutter_local_notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep interface com.dexterous.flutterlocalnotifications.** { *; }
-dontwarn com.dexterous.flutterlocalnotifications.**

# Сохранение generic-типов для TypeToken
-keepattributes Signature
-keepattributes *Annotation*