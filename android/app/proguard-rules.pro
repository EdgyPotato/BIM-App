# Keep SnakeYAML classes
-keep class org.yaml.snakeyaml.** { *; }
-dontwarn org.yaml.snakeyaml.**

# Keep Java beans classes (if available)
-keep class java.beans.** { *; }
-dontwarn java.beans.**

# Keep introspection related classes
-keepclassmembers class * {
    public <init>(...);
}