pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
        // The SteadySense nfctlog Android AAR is published to GitHub Packages.
        // GitHub Packages requires authentication even for public packages: set
        // GITHUB_PACKAGES_USERNAME and GITHUB_PACKAGES_PASSWORD (a PAT with read:packages)
        // in ~/.gradle/gradle.properties or this project's gradle.properties. See README.md.
        maven {
            name = "GitHubPackagesRelease"
            url = uri("https://maven.pkg.github.com/steadysense/nfctlog-mobile-release")
            credentials {
                username = providers.gradleProperty("GITHUB_PACKAGES_USERNAME").orNull
                password = providers.gradleProperty("GITHUB_PACKAGES_PASSWORD").orNull
            }
        }
    }
}

rootProject.name = "nfctlog-android-example"
include(":app")
