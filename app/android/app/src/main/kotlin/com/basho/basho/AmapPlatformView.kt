package com.basho.basho

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.view.View
import android.widget.FrameLayout
import com.amap.api.maps.AMap
import com.amap.api.maps.CameraUpdateFactory
import com.amap.api.maps.TextureMapView
import com.amap.api.maps.model.BitmapDescriptorFactory
import com.amap.api.maps.model.LatLng
import com.amap.api.maps.model.LatLngBounds
import com.amap.api.maps.model.Marker
import com.amap.api.maps.model.MarkerOptions
import com.amap.api.maps.model.Polyline
import com.amap.api.maps.model.PolylineOptions
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

/**
 * 高德原生地图 PlatformView。
 * 用 TextureMapView（纹理渲染，避免 SurfaceView 与 Flutter 合成层的 z-order / 白屏问题）。
 *
 * 稳定性设计：
 *  - 用 FrameLayout 承载，地图创建/初始化失败时**降级为空视图并回报错误**，绝不抛到上层导致 App 闪退；
 *  - 「我的位置」蓝点必须先确认已授予定位权限，否则跳过（未授权时开启会被系统拒绝甚至崩）；
 *  - 所有 Overlay 操作在地图不可用时直接忽略。
 *
 * Dart 侧契约（与 WebView 版同构）：
 *   MethodChannel  "basho/amap_<viewId>"        : render / renderNav / moveTo / fitRoute / refresh / resume / pause
 *   EventChannel   "basho/amap_events_<viewId>" : {type: ready|tap|error, ...}
 */
class AmapViewFactory(private val messenger: BinaryMessenger) :
    PlatformViewFactory(StandardMessageCodec.INSTANCE) {

    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        @Suppress("UNCHECKED_CAST")
        val params = (args as? Map<String, Any?>) ?: emptyMap()
        return AmapPlatformView(context, messenger, viewId, params)
    }
}

class AmapPlatformView(
    context: Context,
    messenger: BinaryMessenger,
    viewId: Int,
    private val params: Map<String, Any?>,
) : PlatformView {

    /** 承载视图：即使地图创建失败，也能安全返回一个空视图 */
    private val rootView = FrameLayout(context)

    private var mapView: TextureMapView? = null
    private var aMap: AMap? = null

    private val channel = MethodChannel(messenger, "basho/amap_$viewId")
    private val events = EventChannel(messenger, "basho/amap_events_$viewId")
    private var sink: EventChannel.EventSink? = null

    /** 事件通道尚未被 Dart 监听时的错误暂存（就绪后补发） */
    private var pendingError: String? = null

    private var pathLine: Polyline? = null
    private var doneLine: Polyline? = null
    private var todoLine: Polyline? = null
    private val markers = mutableListOf<Marker>()

    init {
        // ① 创建地图（失败则降级，不崩）
        try {
            val mv = TextureMapView(context)
            mapView = mv
            aMap = mv.map
            rootView.addView(
                mv,
                FrameLayout.LayoutParams(
                    FrameLayout.LayoutParams.MATCH_PARENT,
                    FrameLayout.LayoutParams.MATCH_PARENT
                )
            )
            mv.onCreate(null)
            mv.onResume()
        } catch (t: Throwable) {
            mapView = null
            aMap = null
            rootView.removeAllViews()
            reportError("原生地图初始化失败：${t.message ?: t.javaClass.simpleName}")
        }

        // ② 地图基础设置（仅当可用）
        aMap?.let { m ->
            try {
                m.mapType = mapTypeOf(params["mapType"] as? String)
                m.uiSettings.isZoomControlsEnabled = false
                m.uiSettings.isCompassEnabled = false
                m.uiSettings.isMyLocationButtonEnabled = false
                val zoom = (params["zoom"] as? Number)?.toFloat() ?: 15f
                m.moveCamera(CameraUpdateFactory.zoomTo(zoom))
                (params["center"] as? List<*>)?.let { c ->
                    if (c.size >= 2) {
                        m.moveCamera(
                            CameraUpdateFactory.newLatLngZoom(
                                LatLng((c[1] as Number).toDouble(), (c[0] as Number).toDouble()),
                                zoom
                            )
                        )
                    }
                }
                m.setOnMapClickListener { latLng ->
                    emit(mapOf("type" to "tap", "lng" to latLng.longitude, "lat" to latLng.latitude))
                }
            } catch (t: Throwable) {
                reportError("地图基础设置失败：${t.message ?: t.javaClass.simpleName}")
            }

            // ③ 「我的位置」蓝点：必须先确认权限，未授权直接跳过（否则系统会拒绝/崩溃）
            if (params["myLocationEnabled"] == true) {
                if (hasLocationPermission(context)) {
                    try {
                        m.isMyLocationEnabled = true
                    } catch (t: Throwable) {
                        reportError("开启定位蓝点失败：${t.message ?: t.javaClass.simpleName}")
                    }
                } else {
                    reportError("未授予定位权限，已跳过地图蓝点")
                }
            }
        }

        // ④ 命令通道
        channel.setMethodCallHandler { call: MethodCall, result: MethodChannel.Result ->
            try {
                when (call.method) {
                    "render" -> { renderPath(call); result.success(null) }
                    "renderNav" -> { renderNavPath(call); result.success(null) }
                    "moveTo" -> { moveTo(call); result.success(null) }
                    "fitRoute" -> { fitRoute(); result.success(null) }
                    "refresh", "resume" -> { mapView?.onResume(); result.success(null) }
                    "setMapType" -> {
                        aMap?.mapType = mapTypeOf(call.argument<String>("type"))
                        result.success(null)
                    }
                    "pause" -> { mapView?.onPause(); result.success(null) }
                    else -> result.notImplemented()
                }
            } catch (t: Throwable) {
                // 任何异常都只回报错误，绝不向外抛（避免 App 崩溃）
                result.error("amap_error", t.message, null)
            }
        }

        // ⑤ 事件通道
        events.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, s: EventChannel.EventSink?) {
                sink = s
                pendingError?.let { emit(mapOf("type" to "error", "msg" to it)); pendingError = null }
                emit(mapOf("type" to "ready"))
            }

            override fun onCancel(arguments: Any?) {
                sink = null
            }
        })
    }

    private fun mapTypeOf(type: String?): Int =
        if (type == "satellite") AMap.MAP_TYPE_SATELLITE else AMap.MAP_TYPE_NORMAL

    private fun hasLocationPermission(ctx: Context): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return true
        return ctx.checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION) ==
            PackageManager.PERMISSION_GRANTED ||
            ctx.checkSelfPermission(Manifest.permission.ACCESS_COARSE_LOCATION) ==
            PackageManager.PERMISSION_GRANTED
    }

    private fun reportError(msg: String) {
        val s = sink
        if (s != null) {
            s.success(mapOf("type" to "error", "msg" to msg))
        } else {
            pendingError = msg
        }
    }

    private fun emit(payload: Map<String, Any?>) {
        sink?.success(payload)
    }

    private fun toLatLngList(raw: Any?): List<LatLng> {
        val out = mutableListOf<LatLng>()
        (raw as? List<*>)?.forEach { item ->
            val pair = item as? List<*>
            if (pair != null && pair.size >= 2) {
                val lng = (pair[0] as? Number)?.toDouble()
                val lat = (pair[1] as? Number)?.toDouble()
                if (lng != null && lat != null) out.add(LatLng(lat, lng))
            }
        }
        return out
    }

    private fun clearOverlays() {
        pathLine?.remove(); pathLine = null
        doneLine?.remove(); doneLine = null
        todoLine?.remove(); todoLine = null
        markers.forEach { runCatching { it.remove() } }
        markers.clear()
    }

    /** 定制路线/轨迹：锚点 + 一条主路径 */
    private fun renderPath(call: MethodCall) {
        val m = aMap ?: return
        clearOverlays()
        val path = toLatLngList(call.argument("path"))
        if (path.size >= 2) {
            pathLine = m.addPolyline(
                PolylineOptions().addAll(path)
                    .color(0xFFFC4C02.toInt())
                    .width(14f)
            )
        }
        toLatLngList(call.argument("anchors")).forEachIndexed { index, latLng ->
            markers.add(
                m.addMarker(
                    MarkerOptions().position(latLng)
                        .icon(BitmapDescriptorFactory.defaultMarker(if (index == 0) 200f else 30f))
                        .anchor(0.5f, 0.5f)
                )
            )
        }
        val myLoc = call.argument<List<Double>>("myLoc")
        if (myLoc != null && myLoc.size >= 2) {
            markers.add(m.addMarker(MarkerOptions().position(LatLng(myLoc[1], myLoc[0]))))
        }
    }

    /** 导航：已骑（灰）/ 未骑（橙）双色 + 当前位置 */
    private fun renderNavPath(call: MethodCall) {
        val m = aMap ?: return
        clearOverlays()
        val done = toLatLngList(call.argument("done"))
        val todo = toLatLngList(call.argument("todo"))
        if (done.size >= 2) {
            doneLine = m.addPolyline(
                PolylineOptions().addAll(done).color(0xFF9A9AA5.toInt()).width(16f)
            )
        }
        if (todo.size >= 2) {
            todoLine = m.addPolyline(
                PolylineOptions().addAll(todo).color(0xFFFC4C02.toInt()).width(16f)
            )
        }
        val me = call.argument<List<Double>>("me")
        if (me != null && me.size >= 2) {
            markers.add(
                m.addMarker(
                    MarkerOptions().position(LatLng(me[1], me[0]))
                        .icon(BitmapDescriptorFactory.defaultMarker(BitmapDescriptorFactory.HUE_AZURE))
                )
            )
        }
    }

    private fun moveTo(call: MethodCall) {
        val m = aMap ?: return
        val lng = call.argument<Double>("lng") ?: return
        val lat = call.argument<Double>("lat") ?: return
        val zoom = call.argument<Double>("zoom")?.toFloat() ?: 16f
        m.animateCamera(CameraUpdateFactory.newLatLngZoom(LatLng(lat, lng), zoom))
    }

    private fun fitRoute() {
        val m = aMap ?: return
        val lines = listOfNotNull(todoLine ?: pathLine, doneLine).filter { it.points.isNotEmpty() }
        if (lines.isEmpty()) return
        val builder = LatLngBounds.Builder()
        lines.forEach { line -> line.points.forEach { builder.include(it) } }
        try {
            m.moveCamera(CameraUpdateFactory.newLatLngBounds(builder.build(), 60))
        } catch (_: Throwable) {
            // 单点/退化路线时 newLatLngBounds 会抛异常，忽略即可
        }
    }

    override fun getView(): View = rootView

    override fun dispose() {
        channel.setMethodCallHandler(null)
        events.setStreamHandler(null)
        sink = null
        runCatching { mapView?.onPause() }
        runCatching { mapView?.onDestroy() }
        mapView = null
        aMap = null
    }
}
