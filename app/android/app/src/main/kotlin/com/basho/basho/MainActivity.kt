package com.basho.basho

import com.amap.api.maps.MapsInitializer
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // 高德合规：必须在任何地图创建之前声明隐私政策已展示并同意（2022+ SDK 要求）
        MapsInitializer.updatePrivacyShow(this, true, true)
        MapsInitializer.updatePrivacyAgree(this, true)

        // 注册原生地图 PlatformView（viewType: basho/amap）
        flutterEngine.platformViewsController.registry.registerViewFactory(
            "basho/amap",
            AmapViewFactory(flutterEngine.dartExecutor.binaryMessenger),
        )
    }
}
