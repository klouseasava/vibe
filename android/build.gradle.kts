allprojects {
    repositories {
        google()
        mavenCentral()
    }
    
    // This block forces EVERY sub-module (including JNI and plugins) 
    // to use the stable NDK version immediately.
    tasks.withType<com.android.build.gradle.tasks.ExternalNativeBuildJsonTask> {
        doFirst {
            val android = project.extensions.getByName("android") as com.android.build.gradle.BaseExtension
            android.ndkVersion = "25.1.8937393"
        }
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
    
    // Secondary safety lock
    plugins.withType<com.android.build.gradle.BasePlugin> {
        val android = project.extensions.getByName("android") as com.android.build.gradle.BaseExtension
        android.ndkVersion = "25.1.8937393"
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}