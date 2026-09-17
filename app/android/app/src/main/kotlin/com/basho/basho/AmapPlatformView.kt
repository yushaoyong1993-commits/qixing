package com.basho.basho

import android.content.Context
import com.amap.api.maps.AMap
import com.amap.api.maps.CameraUpdateFactory
import com.amap.api.maps.TextureMapView
import com.amap.api.maps.model.BitmapDescriptorFactory
import com.amap.api.maps.model.LatLng
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
 * Dart 侧契约（与 WebView 版 AmapMapView 同构，便于页面无感迁移）：
 *   MethodChannel  "basho/amap_<viewId>"        : render / renderNav / moveTo / fitRoute / refresh
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

    private val mapView = TextureMapView(context)
    private val aMap: AMap = mapView.map
    private val channel = MethodChannel(messenger, "basho/amap_$viewId")
    private val events = EventChannel(messenger, "basho/amap_events_$viewId")
    private var sink: EventChannel.EventSink? = null

    private var pathLine: Polyline? = null
    private var doneLine: Polyline? = null
    private var todoLine: Polyline? = null
    private val markers = mutableListOf<Marker>()

    init {
        mapView.onCreate(null)
        mapView.onResume()

        aMap.mapType = AMap.MAP_TYPE_NORMAL
        aMap.uiSettings.isZoomControlsEnabled = false
        aMap.uiSettings.isCompassEnabled = false
        aMap.uiSettings.isMyLocationButtonEnabled = false
        aMap.moveCamera(CameraUpdateFactory.zoomTo((params["zoom"] as? Number)?.toFloat() ?: 15f))
        (params["center"] as? List<*>)?.let { c ->
            if (c.size >= 2) {
                aMap.moveCamera(
                    CameraUpdateFactory.newLatLngZoom(
                        LatLng((c[1] as Number).toDouble(), (c[0] as Number).toDouble()),
                        (params["zoom"] as? Number)?.toFloat() ?: 15f
                    )
                )
            }
        }
        if (params["myLocationEnabled"] == true) {
            try {
                aMap.isMyLocationEnabled = true
            } catch (e: SecurityException) {
                emit(mapOf("type" to "error", "msg" to "定位权限未授予，地图无法显示蓝点"))
            }
        }

        aMap.setOnMapClickListener { latLng ->
            emit(mapOf("type" to "tap", "lng" to latLng.longitude, "lat" to latLng.latitude))
        }

        channel.setMethodCallHandler { call: MethodCall, result: MethodChannel.Result ->
            try {
                when (call.method) {
                    "render" -> { renderPath(call); result.success(null) }
                    "renderNav" -> { renderNavPath(call); result.success(null) }
                    "moveTo" -> { moveTo(call); result.success(null) }
                    "fitRoute" -> { fitRoute(); result.success(null) }
                    "refresh" -> { mapView.onResume(); result.success(null) }
                    else -> result.notImplemented()
                }
            } catch (e: Exception) {
                result.error("amap_error", e.message, null)
            }
        }

        events.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, s: EventChannel.EventSink?) {
                sink = s
                emit(mapOf("type" to "ready"))
            }

            override fun onCancel(arguments: Any?) {
                sink = null
            }
        })
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
        markers.forEach { it.remove() }
        markers.clear()
    }

    /** 定制路线/轨迹：锚点 + 一条主路径 */
    private fun renderPath(call: MethodCall) {
        clearOverlays()
        val path = toLatLngList(call.argument("path"))
        if (path.size >= 2) {
            pathLine = aMap.addPolyline(
                PolylineOptions().addAll(path)
                    .color(0xFFFC4C02.toInt())
                    .width(14f)
            )
        }
        val anchors = toLatLngList(call.argument("anchors"))
        anchors.forEachIndexed { index, latLng ->
            markers.add(
                aMap.addMarker(
                    MarkerOptions().position(latLng)
                        .icon(BitmapDescriptorFactory.defaultMarker(if (index == 0) 200f else 30f))
                        .anchor(0.5f, 0.5f)
                )
            )
        }
        val myLoc = call.argument<List<Double>>("myLoc")
        if (myLoc != null && myLoc.size >= 2) {
            markers.add(aMap.addMarker(MarkerOptions().position(LatLng(myLoc[1], myLoc[0]))))
        }
    }

    /** 导航：已骑（灰）/ 未骑（橙）双色 + 当前位置 */
    private fun renderNavPath(call: MethodCall) {
        clearOverlays()
        val done = toLatLngList(call.argument("done"))
        val todo = toLatLngList(call.argument("todo"))
        if (done.size >= 2) {
            doneLine = aMap.addPolyline(
                PolylineOptions().addAll(done).color(0xFF9A9AA5.toInt()).width(16f)
            )
        }
        if (todo.size >= 2) {
            todoLine = aMap.addPolyline(
                PolylineOptions().addAll(todo).color(0xFFFC4C02.toInt()).width(16f)
            )
        }
        val me = call.argument<List<Double>>("me")
        if (me != null && me.size >= 2) {
            markers.add(
                aMap.addMarker(
                    MarkerOptions().position(LatLng(me[1], me[0]))
                        .icon(BitmapDescriptorFactory.defaultMarker(BitmapDescriptorFactory.HUE_AZURE))
                )
            )
        }
    }

    private fun moveTo(call: MethodCall) {
        val lng = call.argument<Double>("lng") ?: return
        val lat = call.argument<Double>("lat") ?: return
        val zoom = call.argument<Double>("zoom")?.toFloat() ?: 16f
        aMap.animateCamera(CameraUpdateFactory.newLatLngZoom(LatLng(lat, lng), zoom))
    }

    private fun fitRoute() {
        val overlays = listOfNotNull(todoLine ?: pathLine, doneLine).filter { it.points.isNotEmpty() }
        if (overlays.isEmpty()) return
        val builder = com.amap.api.maps.model.LatLngBounds.Builder()
        overlays.forEach { line -> line.points.forEach { builder.include(it) } }
        try {
            aMap.moveCamera(CameraUpdateFactory.newLatLngBounds(builder.build(), 60))
        } catch (_: Exception) {
        }
    }

    override fun getView(): android.view.View = mapView

    override fun dispose() {
        channel.setMethodCallHandler(null)
        events.setStreamHandler(null)
        sink = null
        mapView.onPause()
        mapView.onDestroy()
    }
}
