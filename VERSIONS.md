# Toolchain Versions

These are the build tool versions this project is verified against. Use these exact versions and the app builds without any version fixing.

Last verified: 2026-10-24, debug build running on an Android 14 device (Samsung SM E236B).

## SDKs

| Tool    | Version            | Notes                                              |
|---------|--------------------|----------------------------------------------------|
| Flutter | **3.47.8** (stable) | Use `flutter --version` to check                   |
| Dart    | **3.13.7**         | Ships with Flutter 3.47.8                          |
| Java    | **25** (OpenJDK 25.0.3) | Android Studio's bundled JBR works too        |

## Android build

| Component                                  | Version          | Defined in                                         |
|--------------------------------------------|------------------|----------------------------------------------------|
| Gradle                                     | **9.1.0**        | `android/gradle/wrapper/gradle-wrapper.properties` |
| Android Gradle Plugin (`com.android.application`) | **8.13.0** | `android/settings.gradle`                        |
| Kotlin (`org.jetbrains.kotlin.android`)    | **2.2.20**       | `android/settings.gradle`                          |
| Google Services plugin                     | **4.4.2**        | `android/settings.gradle`                          |
| compileSdk                                 | **36**           | `android/app/build.gradle`                         |
| targetSdk                                  | **35**           | `android/app/build.gradle`                         |
| minSdk                                     | `flutter.minSdkVersion` | `android/app/build.gradle`                  |
| NDK                                        | **27.0.12077973** | `android/app/build.gradle`                        |

`android/gradle.properties` also sets `android.builtInKotlin=false` and `android.newDsl=false`. Flutter's migrator added them, and they keep the project off the AGP 9 DSL. Don't remove them unless you're migrating to AGP 9.

## Constraints

These combinations are known to break the build:

- **`animations: ^3.0.0` needs Dart ≥ 3.12**, which means Flutter ≥ 3.47. Older Flutter fails at `pub get`.
- **Java 25 needs Gradle ≥ 9.1.0.** With Gradle 8.x you get "Gradle version is incompatible with the Java version".
- **Flutter 3.47 sets minimums of AGP ≥ 8.11.1 and Kotlin ≥ 2.2.20.**
- **Kotlin must be declared in the `plugins {}` block of `settings.gradle`.** An `ext.kotlin_version` in `android/build.gradle` is ignored, and Flutter falls back to Kotlin 2.0.0.

If you must use an older JDK (17 or 21), Gradle 9.1.0 still works with it. Otherwise point Flutter at a JDK with `flutter config --jdk-dir=<path>`.

## Setup on a new machine

```bash
flutter --version        # should report 3.47.8
flutter doctor -v        # check the Java version under "Android toolchain"
flutter pub get
flutter run -d <device-id>
```

## Updating this file

When you change Flutter, Gradle, AGP, Kotlin, Java or SDK levels, update the tables above and the "Last verified" line in the same commit.
