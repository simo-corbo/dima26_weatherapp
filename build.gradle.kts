// Top-level build file: the plugins every module can use. Each module (here only :app) applies them.
plugins {
    alias(libs.plugins.android.application) apply false
    alias(libs.plugins.kotlin.compose) apply false
}
