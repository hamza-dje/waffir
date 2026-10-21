# SharedPreferences JNI calls use exact class names in method descriptors.
-keep,includedescriptorclasses class io.flutter.plugins.sharedpreferences.**ApiRegistrar { *; }

# jni/lib/src/kotlin.dart resolves these coroutine helpers by name at runtime.
-keep,includedescriptorclasses interface kotlin.coroutines.Continuation { *; }
-keep class kotlin.coroutines.intrinsics.** { *; }
-keep class kotlin.Result { *; }
-keep class kotlin.Result$Failure { *; }
-keep class kotlin.Unit { *; }
