// SPDX-FileCopyrightText: © 2024 Sebastian Davids <sdavids@gmx.de>
// SPDX-License-Identifier: Apache-2.0

// https://docs.gradle.org/current/userguide/kotlin_dsl.html

plugins {
  java
  alias(libs.plugins.springBoot)
  alias(libs.plugins.springDependencyManagement)
}

dependencies {
  implementation("org.springframework.boot:spring-boot-starter-web")
}

group = "de.sdavids"
version = "1.0.0"

java {
  toolchain {
    languageVersion = JavaLanguageVersion.of(21)
  }
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
