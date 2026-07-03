import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

data class PubspecVersion(val name: String, val code: Int)

fun readPubspecVersion(pubspecFile: File): PubspecVersion? {
    if (!pubspecFile.exists()) return null
    val versionLine = pubspecFile.readLines()
        .firstOrNull { it.trimStart().startsWith("version:") }
        ?: return null

    val raw = versionLine.substringAfter("version:").trim().trim('"', '\'')
    // Expected: 1.2.3+45
    val name = raw.substringBefore("+").trim()
    val code = raw.substringAfter("+", missingDelimiterValue = "").trim().toIntOrNull()
        ?: return null

    if (name.isBlank()) return null
    return PubspecVersion(name = name, code = code)
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

val pubspecVersion = readPubspecVersion(rootProject.file("../pubspec.yaml"))

android {
    namespace = "com.webspider.aquasort.mobile"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.webspider.aquasort.mobile"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = pubspecVersion?.code ?: flutter.versionCode
        versionName = pubspecVersion?.name ?: flutter.versionName
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = keystoreProperties["storeFile"]?.let { file(it as String) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            // Enable R8/ProGuard for code shrinking & obfuscation
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
    // The deobfuscation (mapping) file is auto-generated at:
    //   build/outputs/mapping/release/mapping.txt
    // Upload this to Google Play Console for each release to symbolicate
    // crashes and ANRs.
}

flutter {
    source = "../.."
}
