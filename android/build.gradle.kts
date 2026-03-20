allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// Force Java compile options to 17 for all plugin subprojects so they
// match the Kotlin JVM target. The Kotlin task itself is already at 17
// via KGP 2.x defaults; Java lags behind at 1.8 without this override.
subprojects {
    afterEvaluate {
        tasks.withType(JavaCompile::class.java).configureEach {
            sourceCompatibility = "17"
            targetCompatibility = "17"
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
