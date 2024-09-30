// SPDX-FileCopyrightText: © 2024 Sebastian Davids <sdavids@gmx.de>
// SPDX-License-Identifier: Apache-2.0

// https://docs.gradle.org/current/userguide/kotlin_dsl.html

plugins {
  java
  alias(libs.plugins.quarkusPlugin)
}

dependencies {
  implementation(enforcedPlatform(libs.quarkusPlatform))
  implementation("io.quarkus:quarkus-rest")
}

group = "de.sdavids"
version = "1.0.0"

java {
  toolchain {
    languageVersion = JavaLanguageVersion.of(21)
  }
}

tasks.quarkusDev {
  workingDirectory = rootProject.layout.projectDirectory.asFile
}

tasks.withType<JavaCompile>().configureEach {
  options.apply {
    isDeprecation = true
    compilerArgs.addAll(
      arrayOf(
        "-parameters",
        "-Werror",
        "-Xlint:all",
      ),
    )
  }
}
