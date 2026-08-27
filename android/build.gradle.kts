plugins {
    id("com.google.gms.google-services") version "4.4.4" apply false
}

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
    tasks.configureEach {
        if (name == "compileReleaseJavaWithJavac" && project.tasks.findByName("compileReleaseKotlin") != null) {
            dependsOn("compileReleaseKotlin")
        }
        if (name == "compileDebugJavaWithJavac" && project.tasks.findByName("compileDebugKotlin") != null) {
            dependsOn("compileDebugKotlin")
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
