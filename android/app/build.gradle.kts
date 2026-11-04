plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.cuan_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.cuan_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_11
    }
}

flutter {
    source = "../.."
}

// Nama file APK yang enak dibagikan: "Cuan App V<versi>.apk" (versi = versionName di pubspec.yaml).
// Untuk build staging isi env APK_PREFIX, mis. APK_PREFIX="[Stag] - " -> "[Stag] - Cuan App V1.0.0.apk".
//
// Dibuat sebagai SALINAN di folder yang sama dengan app-release.apk, bukan mengganti nama aslinya:
// `flutter build apk` mencari app-release.apk setelah Gradle selesai, jadi kalau file itu diganti
// namanya perintah build dianggap gagal walau APK-nya sudah jadi.
//
// Sengaja tugas biasa TANPA input/output terdaftar (bukan tipe Copy): kalau folder flutter-apk
// dideklarasikan sebagai output, Gradle menghapusnya sebagai "keluaran lama" saat tugas ini
// dijalankan dan APK asli ikut hilang.
val apkVersion = flutter.versionName
val apkPrefix = System.getenv("APK_PREFIX") ?: ""
val apkOutputDir = layout.buildDirectory.dir("outputs/flutter-apk")
val namedApk = tasks.register("copyNamedReleaseApk") {
    doLast {
        val dir = apkOutputDir.get().asFile
        // universal: app-release.apk | split per ABI: app-arm64-v8a-release.apk -> "... V1.0.0 arm64-v8a.apk"
        val pattern = Regex("^app-(?:(.+)-)?release[.]apk$")
        dir.listFiles()?.forEach { file ->
            val abi = pattern.find(file.name)?.let { it.groupValues[1] } ?: return@forEach
            val named = "${apkPrefix}Cuan App V$apkVersion" + (if (abi.isNotEmpty()) " $abi" else "") + ".apk"
            file.copyTo(File(dir, named), overwrite = true)
            println("APK bernama: ${File(dir, named)}")
        }
    }
}
tasks.matching { it.name == "assembleRelease" }.configureEach { finalizedBy(namedApk) }
