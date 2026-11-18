import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Konfigurasi signing release LOKAL (tidak pernah di-commit).
// Buat android/key.properties berdasarkan key.properties.example dan sediakan
// keystore di lokasi yang sama. JANGAN pernah commit key.properties / *.keystore / *.jks.
val keyPropertiesFile = rootProject.file("key.properties")
val hasReleaseSigning = keyPropertiesFile.exists()
val keyProperties = Properties().apply {
    if (hasReleaseSigning) keyPropertiesFile.inputStream().use { load(it) }
}
check(!hasReleaseSigning || keyProperties.getProperty("storeFile") != null) {
    "android/key.properties ditemukan tetapi properti 'storeFile' tidak ada. " +
        "Periksa formatnya (lihat android/key.properties.example)."
}

android {
    namespace = "com.example.siakad_mobile"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // Application ID existing installations — JANGAN diubah tanpa koordinasi rilis.
        applicationId = "com.example.siakad_mobile"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                storeFile = rootProject.file(keyProperties.getProperty("storeFile")!!)
                storePassword = keyProperties.getProperty("storePassword")
                keyAlias = keyProperties.getProperty("keyAlias")
                keyPassword = keyProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            if (hasReleaseSigning) {
                signingConfig = signingConfigs.getByName("release")
            } else {
                // Signing BELUM tersedia: JANGAN diam-diam pakai debug key.
                // `flutter build apk --release` / `appbundle` harus GAGAL JELAS
                // dengan instruksi — bukan menghasilkan artefak release palsu.
                // Konfigurasi debug tetap normal; hanya task release yang gagal.
                gradle.taskGraph.whenReady {
                    val wantsRelease = allTasks.any { task ->
                        task.path.contains("Release", ignoreCase = true)
                    }
                    if (wantsRelease) {
                        throw GradleException(
                            "Release signing belum dikonfigurasi. " +
                                "Buat android/key.properties dari key.properties.example, " +
                                "sediakan keystore, lalu jalankan ulang " +
                                "`flutter build apk --release` / `flutter build appbundle --release`. " +
                                "Build debug (`flutter build apk --debug`) tidak terpengaruh. " +
                                "Lihat docs/ANDROID_RELEASE_GUIDE.md.",
                        )
                    }
                }
            }
        }
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
