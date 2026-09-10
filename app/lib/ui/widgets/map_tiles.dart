import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 天地图 token（tk）：到 https://console.tianditu.gov.cn 申请「浏览器端」key 后填入。
/// 留空时天地图源会自动回退到 Esri，保证仍能看地图。
// 浏览器端 key（瓦片请求用）
const String kTiandituToken = 'a357f44a7a604298e9299b37f97472f7';
// 备用：安卓端 key（若浏览器端 key 在真机被 referer 校验拦下，可换这个试）
const String kTiandituTokenAndroid = 'a357f44a7a604298e9299b37f97472f7';

/// 可选地图瓦片源。
enum MapTileSource { tianditu, esri, osm, amap }

String tileSourceLabel(MapTileSource s) => switch (s) {
      MapTileSource.tianditu => '天地图',
      MapTileSource.esri => 'Esri',
      MapTileSource.osm => 'OSM',
      MapTileSource.amap => '高德',
    };

/// 当前选用的瓦片源（默认天地图；tk 为空时自动回退 Esri）。
final mapTileSourceProvider =
    StateProvider<MapTileSource>((ref) => MapTileSource.tianditu);

/// 天地图需要"底图 + 注记"两层叠加。
List<TileLayer> tileLayersFor(MapTileSource s, {void Function()? onError}) {
  switch (s) {
    case MapTileSource.tianditu:
      if (kTiandituToken.trim().isEmpty) return [esriTileLayer()]; // 未配置 tk → 回退
      return [tiandituVecLayer(onError), tiandituCvaLayer(onError)];
    case MapTileSource.esri:
      return [esriTileLayer()];
    case MapTileSource.osm:
      return [osmTileLayer()];
    case MapTileSource.amap:
      return [amapTileLayer()];
  }
}

/// 天地图矢量底图（EPSG:3857，与 GPS 的 WGS84 经纬度一致，轨迹不偏移）
TileLayer tiandituVecLayer([void Function()? onError]) => TileLayer(
      urlTemplate:
          'https://t{s}.tianditu.gov.cn/DataServer?T=vec_w&x={x}&y={y}&l={z}&tk=$kTiandituToken',
      subdomains: const ['0', '1', '2', '3', '4', '5', '6', '7'],
      userAgentPackageName: 'com.basho.basho',
      errorTileCallback: (tile, error, stack) => onError?.call(),
    );

/// 天地图矢量注记（中文地名/路名）
TileLayer tiandituCvaLayer([void Function()? onError]) => TileLayer(
      urlTemplate:
          'https://t{s}.tianditu.gov.cn/DataServer?T=cva_w&x={x}&y={y}&l={z}&tk=$kTiandituToken',
      subdomains: const ['0', '1', '2', '3', '4', '5', '6', '7'],
      userAgentPackageName: 'com.basho.basho',
      errorTileCallback: (tile, error, stack) => onError?.call(),
    );

/// 高德路网瓦片（无需 key；对非官方客户端可能灰白）
TileLayer amapTileLayer() => TileLayer(
      urlTemplate:
          'https://webrd0{s}.is.autonavi.com/appmaptile?style=7&x={x}&y={y}&z={z}',
      subdomains: const ['1', '2', '3', '4'],
      userAgentPackageName: 'com.basho.basho',
      tileProvider: NetworkTileProvider(headers: {
        'Referer': 'https://www.amap.com/',
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
      }),
    );

/// Esri 全球街道图（无需 key，海外源）
TileLayer esriTileLayer() => TileLayer(
      urlTemplate:
          'https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/{z}/{y}/{x}',
      userAgentPackageName: 'com.basho.basho',
    );

/// OpenStreetMap（无需 key，海外源）
TileLayer osmTileLayer() => TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'com.basho.basho',
    );
