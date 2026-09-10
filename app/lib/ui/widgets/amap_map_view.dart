import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// 高德 JS API key（「Web端(JS API)」类型）
const String kAmapJsKey = 'a69189b5269db2903026fc6f51165eb9';

/// 高德 JS API 安全密钥（securityJsCode，2021-12 之后申请的 key 必填）。
/// 控制台 → 应用管理 → 该 key → 查看「安全密钥」。
const String kAmapSecurityJsCode = '8fa7afee1bfda7d5e8a1e8061f5dd3a6';

/// 高德 JS 地图页（WebView）。职责只有两件：渲染（底图/锚点/路径/我的位置）+ 把点击坐标回传。
/// 规划请求由 Flutter 侧发起（直接调用高德 Web 服务，坐标全程 GCJ-02，零转换）。
class AmapMapView extends StatefulWidget {
  const AmapMapView({
    super.key,
    required this.onTapLngLat,
    this.onReady,
    this.onError,
    this.initialZoom = 15,
  });

  final void Function(double lng, double lat) onTapLngLat;
  final VoidCallback? onReady;
  final void Function(String msg)? onError;
  final double initialZoom;

  @override
  State<AmapMapView> createState() => AmapMapViewState();
}

class AmapMapViewState extends State<AmapMapView> with WidgetsBindingObserver {
  late final WebViewController _c;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _c = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFFF2F2F5))
      ..addJavaScriptChannel('Basho', onMessageReceived: _onJsMessage)
      ..loadHtmlString(_html(), baseUrl: 'https://www.amap.com/');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// App 回到前台 / 页面重新可见时刷新地图（防止 WebView 表面丢失变白）
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) refresh();
  }

  /// 强制刷新（resize + 保持当前层级）
  void refresh() {
    if (!_ready) return;
    _c.runJavaScript('refreshMap();');
  }

  @override
  Widget build(BuildContext context) => WebViewWidget(controller: _c);

  void _onJsMessage(JavaScriptMessage m) {
    try {
      final data = jsonDecode(m.message) as Map<String, dynamic>;
      switch (data['type']) {
        case 'ready':
          _ready = true;
          widget.onReady?.call();
          break;
        case 'tap':
          widget.onTapLngLat((data['lng'] as num).toDouble(), (data['lat'] as num).toDouble());
          break;
        case 'error':
          widget.onError?.call('${data['msg']}');
          break;
      }
    } catch (_) {}
  }

  /// 重绘：锚点、路径、我的位置（坐标均为 GCJ-02 的 [lng, lat]）
  void render({
    List<List<double>> anchors = const [],
    List<List<double>> path = const [],
    List<double>? myLoc,
  }) {
    if (!_ready) return;
    final payload = jsonEncode({'anchors': anchors, 'path': path, 'myLoc': myLoc});
    _c.runJavaScript('renderMap($payload);');
  }

  void moveTo(double lng, double lat, {double zoom = 16}) {
    if (!_ready) return;
    _c.runJavaScript('moveTo($lng, $lat, $zoom);');
  }

  String _html() => '''
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1,user-scalable=no">
<style>html,body,#map{height:100%;margin:0;padding:0;background:#F2F2F5}</style>
<script>
  window._AMapSecurityConfig = { securityJsCode: '$kAmapSecurityJsCode' };
</script>
<script src="https://webapi.amap.com/maps?v=2.0&key=$kAmapJsKey"></script>
</head>
<body>
<div id="map"></div>
<script>
var map=null, anchorMarkers=[], pathLine=null, myMarker=null;
function post(o){ try{ Basho.postMessage(JSON.stringify(o)); }catch(e){} }
function boot(){
  if(!window.AMap){ post({type:'error',msg:'高德 JS 地图加载失败（key 域名白名单/网络）'}); return; }
  map=new AMap.Map('map',{zoom:${widget.initialZoom},center:[116.397,39.908],resizeEnable:true});
  map.on('click',function(e){ post({type:'tap',lng:e.lnglat.getLng(),lat:e.lnglat.getLat()}); });
  setTimeout(function(){ try{ map.resize(); }catch(e){} }, 400);
  post({type:'ready'});
}
function renderMap(o){
  if(!map) return;
  if(anchorMarkers.length){ map.remove(anchorMarkers); anchorMarkers=[]; }
  if(pathLine){ map.remove(pathLine); pathLine=null; }
  if(o.anchors&&o.anchors.length){
    for(var i=0;i<o.anchors.length;i++){
      var m=new AMap.Marker({position:new AMap.LngLat(o.anchors[i][0],o.anchors[i][1]),
        content:'<div style="width:16px;height:16px;border-radius:50%;background:'+(i===0?'#fff':'#FC4C02')+';border:2px solid #FC4C02"></div>',
        offset:new AMap.Pixel(-8,-8)});
      anchorMarkers.push(m);
    }
    map.add(anchorMarkers);
  }
  if(o.path&&o.path.length>1){
    pathLine=new AMap.Polyline({path:o.path.map(function(p){return new AMap.LngLat(p[0],p[1]);}),
      strokeColor:'#FC4C02',strokeWeight:5,lineJoin:'round',lineCap:'round'});
    map.add(pathLine);
  }
  if(o.myLoc){
    if(myMarker){ map.remove(myMarker); }
    myMarker=new AMap.Marker({position:new AMap.LngLat(o.myLoc[0],o.myLoc[1]),
      content:'<div style="width:16px;height:16px;border-radius:50%;background:#2F80ED;border:3px solid #fff;box-shadow:0 0 4px rgba(0,0,0,.3)"></div>',
      offset:new AMap.Pixel(-8,-8),zIndex:200});
    map.add(myMarker);
  }
}
function moveTo(lng,lat,zoom){ if(map) map.setZoomAndCenter(zoom||16,[lng,lat]); }
function refreshMap(){ if(map){ try{ map.resize(); }catch(e){} } }
boot();
</script>
</body>
</html>
''';
}
