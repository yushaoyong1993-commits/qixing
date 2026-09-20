package com.basho.basho

import android.content.Context
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.lang.reflect.InvocationHandler
import java.lang.reflect.Proxy

/**
 * 高德离线地图（OfflineMapManager）封装。
 *
 * 为什么用反射：高德各版本 SDK 的离线地图类/方法名存在差异（例如进度方法在部分版本是
 * `getcompletePercent()`、部分版本是 `getCompletePercent()`），直接强类型调用一旦对不上
 * 就会编译失败或运行期崩溃。这里用反射 + 候选方法名逐个尝试，能力缺失时返回 false / 空列表，
 * 由 Dart 侧降级提示，保证 App 不崩。
 *
 * Dart 契约：
 *   MethodChannel "basho/offline"        : available / cities / download / pause / remove
 *   EventChannel  "basho/offline_events" : {type: progress|removed|check, ...}
 */
class AmapOffline(private val context: Context, messenger: BinaryMessenger) {

    private val method = MethodChannel(messenger, "basho/offline")
    private val events = EventChannel(messenger, "basho/offline_events")
    private var sink: EventChannel.EventSink? = null

    private var manager: Any? = null
    private var managerClass: Class<*>? = null

    init {
        method.setMethodCallHandler { call: MethodCall, result: MethodChannel.Result ->
            try {
                when (call.method) {
                    "available" -> result.success(ensureManager())
                    "cities" -> result.success(cities())
                    "download" -> result.success(callManager("downloadByCityName", call.argument<String>("name")))
                    "pause" -> result.success(callManager("pause"))
                    "remove" -> result.success(callManager("remove", call.argument<String>("name")))
                    else -> result.notImplemented()
                }
            } catch (t: Throwable) {
                result.error("offline_error", t.message ?: t.javaClass.simpleName, null)
            }
        }
        events.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, s: EventChannel.EventSink?) {
                sink = s
            }

            override fun onCancel(arguments: Any?) {
                sink = null
            }
        })
    }

    /** 反射创建 OfflineMapManager（需要 Context + 下载监听接口的代理实现） */
    private fun ensureManager(): Boolean {
        manager?.let { return true }
        return try {
            val cls = Class.forName("com.amap.api.maps.offlinemap.OfflineMapManager")
            managerClass = cls
            // 监听接口可能是内部接口，两种名字都试
            val listenerCls = runCatching {
                Class.forName("com.amap.api.maps.offlinemap.OfflineMapManager\$OfflineMapDownloadListener")
            }.getOrElse {
                Class.forName("com.amap.api.maps.offlinemap.OfflineMapDownloadListener")
            }
            val handler = InvocationHandler { _, m, args -> onSdkCallback(m.name, args); null }
            val proxy = Proxy.newProxyInstance(listenerCls.classLoader, arrayOf(listenerCls), handler)
            val ctor = cls.getConstructor(Context::class.java, listenerCls)
            manager = ctor.newInstance(context, proxy)
            manager != null
        } catch (t: Throwable) {
            manager = null
            false
        }
    }

    /** SDK 回调 → 事件流 */
    private fun onSdkCallback(name: String, args: Array<out Any?>?) {
        val s = sink ?: return
        try {
            when {
                name.contains("onDownload", ignoreCase = true) -> {
                    val city = args?.getOrNull(0)
                    val percent = (args?.getOrNull(2) as? Number)?.toInt()
                        ?: num(city, "getcompletePercent", "getCompletePercent", "getCompletepercent")
                    s.success(mapOf(
                        "type" to "progress",
                        "name" to (str(city, "getCity") ?: ""),
                        "percent" to (percent ?: 0),
                    ))
                }
                name.contains("onRemove", ignoreCase = true) -> {
                    s.success(mapOf(
                        "type" to "removed",
                        "name" to ((args?.getOrNull(1) as? String) ?: ""),
                        "success" to (args?.getOrNull(0) as? Boolean ?: false),
                    ))
                }
                name.contains("onCheckUpdate", ignoreCase = true) -> {
                    s.success(mapOf(
                        "type" to "check",
                        "name" to ((args?.getOrNull(1) as? String) ?: ""),
                        "hasNew" to (args?.getOrNull(0) as? Boolean ?: false),
                    ))
                }
            }
        } catch (_: Throwable) {
        }
    }

    /** 已下载/可下载城市列表 */
    private fun cities(): List<Map<String, Any?>> {
        if (!ensureManager()) return emptyList()
        val raw = runCatching { invokeManager("getOfflineMapCityList") }.getOrNull() as? List<*> ?: return emptyList()
        val out = ArrayList<Map<String, Any?>>(raw.size)
        for (item in raw) {
            if (item == null) continue
            val cityName = str(item, "getCity") ?: continue
            out.add(
                mapOf(
                    "name" to cityName,
                    "adcode" to (str(item, "getAdcode") ?: ""),
                    "pinyin" to (str(item, "getPinyin") ?: ""),
                    "size" to (num(item, "getSize") ?: 0),
                    "state" to (num(item, "getState") ?: 0),
                    "percent" to (num(item, "getcompletePercent", "getCompletePercent", "getCompletepercent") ?: 0),
                    "version" to (str(item, "getVersion") ?: ""),
                )
            )
        }
        return out
    }

    /** 反射调用无参 / 单参数（String）方法，返回是否调用成功 */
    private fun callManager(name: String, arg: String? = null): Boolean {
        if (!ensureManager()) return false
        return try {
            if (arg != null) {
                invokeManager(name, arg)
            } else {
                invokeManager(name)
            }
            true
        } catch (_: Throwable) {
            false
        }
    }

    private fun invokeManager(name: String, vararg args: Any?): Any? {
        val obj = manager ?: return null
        val cls = managerClass ?: obj.javaClass
        val m = if (args.isEmpty()) {
            cls.getMethod(name)
        } else {
            cls.getMethod(name, *args.map { it?.javaClass ?: Any::class.java }.toTypedArray())
        }
        return m.invoke(obj, *args)
    }

    /** 依次尝试候选方法名（无参）取回值 */
    private fun callObjAny(obj: Any?, vararg names: String): Any? {
        if (obj == null) return null
        for (n in names) {
            val v = runCatching { obj.javaClass.getMethod(n).invoke(obj) }.getOrNull()
            if (v != null) return v
        }
        return null
    }

    private fun str(obj: Any?, vararg names: String): String? =
        callObjAny(obj, *names)?.toString()?.takeIf { it.isNotBlank() && it != "null" }

    private fun num(obj: Any?, vararg names: String): Int? =
        (callObjAny(obj, *names) as? Number)?.toInt()

    fun dispose() {
        runCatching { invokeManager("destroy") }
        manager = null
    }
}
