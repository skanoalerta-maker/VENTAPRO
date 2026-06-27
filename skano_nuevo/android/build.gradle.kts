import org.gradle.api.tasks.Delete
import org.gradle.api.Project
import org.gradle.api.artifacts.dsl.RepositoryHandler
import org.gradle.api.initialization.dsl.ScriptHandler
import org.gradle.kotlin.dsl.*

buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // ✅ OBLIGATORIO PARA FIREBASE + GOOGLE MAPS
        classpath("com.google.gms:google-services:4.4.0")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// ================================
// CONFIGURACIÓN DE BUILD DIRECTORY
// ================================
val newBuildDir = rootProject.layout.buildDirectory
    .dir("../../build")
    .get()

rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

// 🔗 Asegura que :app se evalúe primero (Flutter)
subprojects {
    project.evaluationDependsOn(":app")
}

// 🧹 Tarea clean
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

