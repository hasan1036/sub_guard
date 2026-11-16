# Keeps the notification plugin working in release builds.
# Without these, Android's code shrinker can break saved (scheduled) reminders.
-keep class com.dexterous.** { *; }

# The plugin saves scheduled reminders with Gson.
-keepattributes Signature
-keepattributes *Annotation*
-keep class com.google.gson.** { *; }
-keep class * extends com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken
