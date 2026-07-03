# =============================================================================
# Aqua Sort — R8/ProGuard rules
# =============================================================================
# Strategy: aggressively shrink and obfuscate, but keep everything Flutter,
# Supabase, and reflection-using libraries need at runtime.
# =============================================================================

# -----------------------------------------------------------------------------
# Flutter wrapper
# -----------------------------------------------------------------------------
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-keep class io.flutter.embedding.** { *; }

# -----------------------------------------------------------------------------
# App entry point
# -----------------------------------------------------------------------------
# AndroidManifest references MainActivity by name, so it must not be renamed.
-keep class com.webspider.aquasort.mobile.MainActivity { *; }
-keep class com.webspider.** { *; }

# -----------------------------------------------------------------------------
# Android framework subclasses referenced from manifest/XML
# -----------------------------------------------------------------------------
-keep public class * extends android.app.Activity
-keep public class * extends android.app.Application
-keep public class * extends android.app.Service
-keep public class * extends android.content.BroadcastReceiver
-keep public class * extends android.content.ContentProvider

# Keep custom views referenced from XML (constructor with AttributeSet)
-keepclasseswithmembers class * {
    public <init>(android.content.Context, android.util.AttributeSet);
}
-keepclasseswithmembers class * {
    public <init>(android.content.Context, android.util.AttributeSet, int);
}

# Keep native methods (JNI)
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep Parcelable CREATOR fields (read by framework via reflection)
-keepclassmembers class * implements android.os.Parcelable {
    public static final ** CREATOR;
}

# Keep Serializable plumbing
-keepnames class * implements java.io.Serializable
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    !static !transient <fields>;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Keep enum values()/valueOf() (used by reflection)
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Keep onClick handlers (referenced by name from XML)
-keepclassmembers class * extends android.app.Activity {
    public void *(android.view.View);
}

# -----------------------------------------------------------------------------
# Supabase / Ktor networking
# -----------------------------------------------------------------------------
-keep class io.github.jan.supabase.** { *; }
-keep class io.ktor.** { *; }
-dontwarn io.ktor.**

# -----------------------------------------------------------------------------
# Google Play Services (used by games_services, google_mobile_ads)
# -----------------------------------------------------------------------------
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**
-keep class com.google.games.** { *; }

# -----------------------------------------------------------------------------
# AdMob
# -----------------------------------------------------------------------------
-keep class com.google.ads.** { *; }
-keep class com.google.android.ads.** { *; }
-dontwarn com.google.android.ads.**

# -----------------------------------------------------------------------------
# audioplayers
# -----------------------------------------------------------------------------
-keep class xyz.luan.audioplayers.** { *; }
-dontwarn xyz.luan.audioplayers.**

# -----------------------------------------------------------------------------
# shared_preferences (Android impl uses reflection on the SharedPreferences
# editor and uses androidx.security crypto providers)
# -----------------------------------------------------------------------------
-keep class androidx.security.crypto.** { *; }
-keep class io.flutter.plugins.sharedpreferences.** { *; }

# -----------------------------------------------------------------------------
# image_picker (uses platform FileProviders and Intent extras)
# -----------------------------------------------------------------------------
-keep class io.flutter.plugins.imagepicker.** { *; }

# -----------------------------------------------------------------------------
# app_links (deep link intent filters)
# -----------------------------------------------------------------------------
-keep class com.llfbandit.app_links.** { *; }

# -----------------------------------------------------------------------------
# pin_code_fields / country_code_picker — pure Dart, no Java rules needed
# (kept here for documentation)
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Google Play Core (deferred components / dynamic features)
# We don't use Play Core's on-demand modules, but Flutter's embedding has
# optional references to them. Suppress the missing-class warnings.
# -----------------------------------------------------------------------------
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

# -----------------------------------------------------------------------------
# General reflection / Gson-style deserialization safety
# -----------------------------------------------------------------------------
# If any library uses class-name reflection (Gson/Moshi/kotlinx.serialization
# on JVM), keep the default constructor and field names.
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}
-keepattributes Signature, InnerClasses, EnclosingMethod
-keepattributes RuntimeVisibleAnnotations, RuntimeVisibleParameterAnnotations
-keepattributes AnnotationDefault

# Keep source line numbers in stack traces (helps debugging even with R8)
-keepattributes SourceFile, LineNumberTable
-renamesourcefileattribute SourceFile
