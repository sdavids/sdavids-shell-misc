// SPDX-FileCopyrightText: © 2024 Sebastian Davids <sdavids@gmx.de>
// SPDX-License-Identifier: Apache-2.0

// https://docs.gradle.org/current/dsl/org.gradle.api.initialization.Settings.html

rootProject.name = "sdavids-shell-misc-cert-quarkus"

dependencyResolutionManagement {
  repositories {
    mavenCentral()
  }
}

plugins {
  id("org.gradle.toolchains.foojay-resolver-convention").version("1.0.0")
}
