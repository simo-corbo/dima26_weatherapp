// The build file of the app module: how to build the APK, and which libraries it uses.
plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.compose) // turns @Composable functions into UI code
}

android {
    namespace = "com.example.weather"
    compileSdk {
        version = release(37)
    }

    defaultConfig {
        applicationId = "com.example.weather" // the app's unique name on the phone and on the Play Store
        minSdk = 24                           // the oldest Android it runs on (7.0)
        targetSdk = 37                        // the Android it was tested on
        versionCode = 1
        versionName = "1.0"

        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }
    buildFeatures {
        compose = true
    }
}

dependencies {
    implementation(libs.androidx.core.ktx)
    implementation(libs.androidx.lifecycle.runtime.ktx)
    implementation(libs.androidx.activity.compose)
    // the BOM (bill of materials) picks one version for all the Compose libraries below
    implementation(platform(libs.androidx.compose.bom))
    implementation(libs.androidx.compose.ui)
    implementation(libs.androidx.compose.ui.graphics)
    implementation(libs.androidx.compose.ui.tooling.preview)
    implementation(libs.androidx.compose.material3)
    // Lab 9: the Material icons (settings, search, water drop...), the same set as Flutter's Icons
    implementation(libs.androidx.compose.material.icons.extended)
    // Lab 9: moving between screens
    implementation(libs.androidx.navigation.compose)
    // Lab 9: viewModel(), to create the state shared by the screens
    implementation(libs.androidx.lifecycle.viewmodel.compose)
    debugImplementation(libs.androidx.compose.ui.tooling)
}
