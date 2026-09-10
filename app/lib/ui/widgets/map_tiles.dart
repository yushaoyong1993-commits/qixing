import 'package:flutter_map/flutter_map.dart';

/// 高德路网瓦片（无需 key）。部分环境对瓦片请求做 referer/UA 校验，
/// 这里统一加上 Referer/User-Agent 头；若仍不可用可换成下面注释的 OSM 源。
TileLayer amapTileLayer() => TileLayer(
      urlTemplate:
          'https://webrd0{s}.is.autonavi.com/appmaptile?style=7&x={x}&y={y}&z={z}',
      subdomains: const ['1', '2', '3', '4'],
      userAgentPackageName: 'com.basho.basho',
      tileProvider: NetworkTileProvider(headers: {
        // 注意：不能用 const map —— flutter_map 内部会修改该 map（补默认 header）
        'Referer': 'https://www.amap.com/',
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
      }),
    );

/// 备用：OSM 瓦片（国际源，国内可能慢；高德不可用时切换）
TileLayer osmTileLayer() => TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'com.basho.basho',
    );
