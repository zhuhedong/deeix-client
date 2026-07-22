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

// Force compileSdk 36 on Android library plugins (file_picker etc.).
// flutter_plugin_android_lifecycle requires compileSdk >= 36.
fun org.gradle.api.Project.forceCompileSdk36() {
    pluginManager.withPlugin("com.android.library") {
        val android = extensions.findByName("android") ?: return@withPlugin
        try {
            val m = android.javaClass.methods.firstOrNull {
                it.name == "setCompileSdk" &&
                    it.parameterCount == 1 &&
                    (it.parameterTypes[0] == Int::class.javaPrimitiveType ||
                        it.parameterTypes[0] == Integer::class.java)
            }
            m?.invoke(android, 36)
        } catch (_: Throwable) {
            // ignore
        }
    }
    pluginManager.withPlugin("com.android.application") {
        val android = extensions.findByName("android") ?: return@withPlugin
        try {
            val m = android.javaClass.methods.firstOrNull {
                it.name == "setCompileSdk" &&
                    it.parameterCount == 1 &&
                    (it.parameterTypes[0] == Int::class.javaPrimitiveType ||
                        it.parameterTypes[0] == Integer::class.java)
            }
            m?.invoke(android, 36)
        } catch (_: Throwable) {
            // ignore
        }
    }
}

subprojects {
    forceCompileSdk36()
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
