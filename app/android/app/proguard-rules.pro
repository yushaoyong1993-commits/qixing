# ===== 高德地图 SDK 必备 keep 规则 =====
# 高德 native 层（libAMapOpenMap.so / libAMapSDK_MAP_*.so）会按“类名+方法名”反射调用 Java 侧，
# R8 若裁剪或改名这些类，会在 JNI_OnLoad 阶段触发
#   'JNI DETECTED ERROR: java_class == null in call to GetStaticMethodID' → SIGABRT 闪退。
-keep class com.amap.api.** { *; }
-keep class com.autonavi.** { *; }
-keep class com.loc.** { *; }
-keep class com.amap.api.col.** { *; }
-dontwarn com.amap.api.**
-dontwarn com.autonavi.**

# 保留 native 方法名与注解（JNI 通过名字绑定）
-keepclasseswithmembernames class * {
    native <methods>;
}

# 高德 SDK 内部使用的序列化/枚举相关
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}
