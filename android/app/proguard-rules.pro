# Flutter specific rules (Essential)
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Rules for Google Play Services Base, Tasks, and Auth (Credentials API)
# Using broader wildcards as dependencies can be complex
-keep class com.google.android.gms.common.** { *; }
-keep interface com.google.android.gms.common.** { *; }
-keep class com.google.android.gms.tasks.** { *; }
-keep interface com.google.android.gms.tasks.** { *; }
-keep class com.google.android.gms.auth.** { *; } # Broadened rule for auth
-keep interface com.google.android.gms.auth.** { *; } # Broadened rule for auth

# NEW: Rules for Google Play Core Library (Split Install, etc.)
-keep class com.google.android.play.core.** { *; }
-keep interface com.google.android.play.core.** { *; }

# NEW: Rules for Guava (often a dependency, including reflection)
-keep class com.google.common.** { *; }
-keep interface com.google.common.** { *; }

# NEW: Rule for Java Reflection (if Guava rule isn't enough)
# Try WITHOUT this first. Add only if AnnotatedType error persists.
# -keep class java.lang.reflect.** { *; }

# --- Important: Add rules from missing_rules.txt ---
# R8 generates specific rules it thinks are needed. Open the file:
# C:\Users\ZhuanZ\Downloads\flutter_application_1\build\app\outputs\mapping\release\missing_rules.txt
# Copy ALL the rules from that file and paste them below this line.
# They might look like:
# -keep class com.google.android.gms.auth.api.credentials.Credential { <init>(...); ... }
# (Paste contents of missing_rules.txt here)
# Please add these rules to your existing keep rules in order to suppress warnings.
# This is generated automatically by the Android Gradle plugin.
-dontwarn com.google.android.gms.auth.api.credentials.Credential$Builder
-dontwarn com.google.android.gms.auth.api.credentials.Credential
-dontwarn com.google.android.gms.auth.api.credentials.CredentialPickerConfig$Builder
-dontwarn com.google.android.gms.auth.api.credentials.CredentialPickerConfig
-dontwarn com.google.android.gms.auth.api.credentials.CredentialRequest$Builder
-dontwarn com.google.android.gms.auth.api.credentials.CredentialRequest
-dontwarn com.google.android.gms.auth.api.credentials.CredentialRequestResponse
-dontwarn com.google.android.gms.auth.api.credentials.Credentials
-dontwarn com.google.android.gms.auth.api.credentials.CredentialsClient
-dontwarn com.google.android.gms.auth.api.credentials.HintRequest$Builder
-dontwarn com.google.android.gms.auth.api.credentials.HintRequest
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.SplitInstallException
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManager
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManagerFactory
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest$Builder
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest
-dontwarn com.google.android.play.core.splitinstall.SplitInstallSessionState
-dontwarn com.google.android.play.core.splitinstall.SplitInstallStateUpdatedListener
-dontwarn com.google.android.play.core.tasks.OnFailureListener
-dontwarn com.google.android.play.core.tasks.OnSuccessListener
-dontwarn com.google.android.play.core.tasks.Task
-dontwarn java.lang.reflect.AnnotatedType