import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 当前选用的瓦片源（默认 Esri 全球，首次更可能出图；可在 App 内切换）
final mapTileSourceProvider =
    StateProvider<MapTileSource>((ref) => MapTileSource.esri);

/// 可选地图瓦片源（不同网络/地区可用性不同，App 内可切换）。
enum MapTileSource { amap, esri, osm }

String tileSourceLabel(MapTileSource s) => switch (s) {
      MapTileSource.amap => '高德',
      MapTileSource.esri => 'Esri 全球',
      MapTileSource.osm => 'OSM',
    };

TileLayer tileLayerFor(MapTileSource s) => switch (s) {
      MapTileSource.amap => amapTileLayer(),
      MapTileSource.esri => esriTileLayer(),
      MapTileSource.osm => osmTileLayer(),
    };

/// 高德路网瓦片（无需 key；对部分客户端会校验 referer/UA，可能灰白）
TileLayer amapTileLayer() => TileLayer(
      urlTemplate:
          'https://webrd0{s}.is.autonavi.com/appmaptile?style=7&x={x}&y={y}&z={z}',
      subdomains: const ['1', '2', '3', '4'],
      userAgentPackageName: 'com.basho.basho',
      tileProvider: NetworkTileProvider(headers: {
        // 不能用 const map：flutter_map 内部会修改 headers
        'Referer': 'https://www.amap.com/',
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
      }),
    );

/// Esri 全球街道图（无需 key，海外源，通常可达）
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
