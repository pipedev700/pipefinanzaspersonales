plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.pipefinanzas.app"
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
        // D3 — decisión cerrada en S09: `com.pipefinanzas.app`. Cambiarlo
        // después de publicar es prácticamente imposible (Google Play
        // identifica la app por firma + applicationId).
        applicationId = "com.pipefinanzas.app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // §31 — La versión vive en un solo sitio, `pubspec.yaml`
        // (`version: 1.0.0+1`): aquí no se escribe a mano para que no
        // puedan desincronizarse. `flutter.versionCode` es el 1 y
        // `flutter.versionName` el "1.0.0".
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // S09: el APK de release se firma con la clave de DEBUG a
            // propósito, para que se pueda instalar y probar sin montar una
            // cadena de firma. NO es publicable en Google Play: la clave de
            // debug es pública y cualquiera puede falsificar una "app"
            // firmada con ella.
            //
            // Para publicar, generar la clave propia UNA vez y meterla en
            // `android/key.properties` (fuera de git, ver .gitignore):
            //
            //   keytool -genkey -v -keystore ~/pipe-finanzas.jks \
            //     -keyalg RSA -keysize 2048 -validity 10000 -alias pipe
            //
            // y sustituir esta línea por la firma que lee `key.properties`.
            // SIN ese paso, la primera publicación y todas las siguientes
            // quedan bloqueadas para siempre: la clave no se puede
            // regenerar.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
