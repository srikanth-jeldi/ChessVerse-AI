# Flutter plugins are registered through generated Java code and may use
# reflection internally. Keep their public entry points while R8 removes the
# unused dependency graph around them.
-keep class io.flutter.plugins.** { *; }
-keep class androidx.work.impl.WorkDatabase { *; }
-keep class * extends androidx.room.RoomDatabase { *; }
-keepattributes RuntimeVisibleAnnotations,RuntimeInvisibleAnnotations,AnnotationDefault
