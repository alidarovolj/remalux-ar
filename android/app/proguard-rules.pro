# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.plugin.editing.** { *; }
-dontwarn io.flutter.embedding.**
-dontwarn android.**
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication

# Conscrypt
-keep class org.conscrypt.** { *; }
-keep class com.android.org.conscrypt.** { *; }
-keep class org.apache.harmony.xnet.provider.jsse.** { *; }

# OpenJSSE
-keep class org.openjsse.** { *; }
-keep class org.openjsse.javax.net.ssl.** { *; }
-keep class org.openjsse.net.ssl.** { *; }

# OkHttp
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }
-dontwarn okhttp3.**
-dontwarn okio.**

# Play Core
-keep class com.google.android.play.core.** { *; }
-keep class com.google.android.play.core.splitcompat.** { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Yandex MapKit
-keep class com.yandex.mapkit.** { *; }
-keep class com.yandex.runtime.** { *; }
-dontwarn com.yandex.**

# Keep important Android classes
-keep class android.app.** { *; }
-keep class android.content.** { *; }
-keep class android.support.v4.** { *; }
-keep class androidx.** { *; }

# SSL and Security
-keep class org.conscrypt.** { *; }
-keep class org.openjsse.** { *; }
-keep class javax.net.ssl.** { *; }
-dontwarn org.conscrypt.**
-dontwarn org.openjsse.**
-dontwarn sun.security.**
-dontwarn javax.naming.**
-dontwarn sun.net.**
-dontwarn sun.misc.**
-dontwarn org.apache.harmony.**
-dontwarn com.android.org.conscrypt.**

# Keep serialization
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Keep enums
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Keep all native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep all public and protected methods that could be used by java reflection
-keepclassmembernames class * {
    public protected <methods>;
}

# Keep Parcelables
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

# Keep R8 from stripping interface information
-keep interface * { *; }

# Disable note warnings
-dontnote **

# General rules
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception 

# Keep missing SSL and security classes
-keep class com.android.org.conscrypt.** { *; }
-keep class org.apache.harmony.xnet.provider.jsse.** { *; }
-keep class sun.misc.** { *; }
-keep class sun.net.** { *; }
-keep class sun.security.** { *; }
-keep class sun.util.** { *; }
-keep class org.openjsse.** { *; }

# Keep specific classes that were reported as missing
-keep class sun.security.internal.** { *; }
-keep class sun.security.jca.** { *; }
-keep class sun.security.provider.** { *; }
-keep class sun.security.util.** { *; }
-keep class sun.security.x509.** { *; }
-keep class sun.security.validator.** { *; }

# Keep specific utility classes
-keep class sun.net.www.protocol.http.** { *; }
-keep class sun.net.www.protocol.https.** { *; }
-keep class sun.net.util.** { *; }

# Keep specific crypto classes
-keep class org.openjsse.sun.crypto.** { *; }
-keep class org.openjsse.com.sun.crypto.** { *; }

# Keep specific SSL classes
-keep class org.openjsse.sun.security.ssl.** { *; }
-keep class org.openjsse.com.sun.net.ssl.** { *; }

# Keep specific math classes
-keep class sun.security.util.math.** { *; }
-keep class sun.security.util.math.intpoly.** { *; }

# Keep logging classes
-keep class sun.util.logging.** { *; }

# Keep all interfaces
-keep interface * { *; }

# Keep all enums
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Keep all serializable classes
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
} 