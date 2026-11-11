import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
val hasKeystore = keystorePropertiesFile.exists()
if (hasKeystore) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.antigravity.nonogram.nonogram"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.antigravity.nonogram.nonogram"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (hasKeystore) {
                val keyAliasVal = keystoreProperties.getProperty("keyAlias")
                val keyPasswordVal = keystoreProperties.getProperty("keyPassword")
                val storeFileVal = keystoreProperties.getProperty("storeFile")
                val storePasswordVal = keystoreProperties.getProperty("storePassword")

                if (keyAliasVal.isNullOrEmpty() || keyPasswordVal.isNullOrEmpty() ||
                    storeFileVal.isNullOrEmpty() || storePasswordVal.isNullOrEmpty()) {
                    throw GradleException("Release signing configuration in key.properties is incomplete.")
                }
                val resolvedStoreFile = rootProject.file(storeFileVal)
                if (!resolvedStoreFile.exists()) {
                    throw GradleException("Keystore file '$storeFileVal' specified in key.properties does not exist.")
                }
                keyAlias = keyAliasVal
                keyPassword = keyPasswordVal
                storeFile = resolvedStoreFile
                storePassword = storePasswordVal
            }
        }
    }

    buildTypes {
        release {
            if (hasKeystore) {
                signingConfig = signingConfigs.getByName("release")
            } else {
                signingConfig = null
            }
        }
    }
}

gradle.taskGraph.whenReady {
    val releaseTasks = allTasks.filter { it.name.contains("Release", ignoreCase = true) }
    if (releaseTasks.isNotEmpty() && !hasKeystore) {
        throw GradleException(
            "Release build rejected: 'key.properties' is missing. A secure release keystore configuration is required; debug signing fallback is strictly prohibited."
        )
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
