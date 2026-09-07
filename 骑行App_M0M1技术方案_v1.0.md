# M0/M1 技术方案（跋涉 · 骑行 App）

## 0. 文档信息

| 项 | 内容 |
|---|---|
| 文档版本 | v1.0（草稿，待评审） |
| 日期 | 2026-09-07 |
| 依据 | 《骑行App需求文档_v0.3.md》§6/§7/§8/§12；页面 PRD（首页 v1.1 / 地图 v1.1 / 记录 v1.1 / 我的 v1.0 / 统计 v1.1 / 活动 v1.1） |
| 覆盖 | M0（骨架）与 M1（记录闭环 + 轻导航 + 统计 P0）的**技术实现方案**；M2+ 仅做架构预留 |
| 性质 | 可选可改；涉及选型处给出建议与回退触发条件 |

---

## 1. 目标与范围

### 1.1 本方案回答
1. 用什么技术栈做 iOS + Android 双端？
2. 代码与模块怎么组织，保证「首页概览 / 我的总览 / 统计页」口径同源？
3. 记录会话（GPS/后台/被杀/草稿）状态机与双平台后台方案；
4. 地图引擎抽象与"一套轨迹渲染到处复用"怎么落地；
5. 本地数据模型（表结构）长什么样；
6. M1 拆多少天、先验证哪些技术风险。

### 1.2 非目标（M1 不做）
- M2 完整导航（turn-by-turn/自动规划/离线完善/分享）、外设（M3）、导入导出（M2）、账号云同步（V2）。

---

## 2. 技术选型

### 2.1 框架建议：Flutter（自研 UI）＋ 原生能力通道

| 维度 | Flutter（推荐） | React Native | 双原生 |
|---|---|---|---|
| 单代码库覆盖 iOS/Android | ✅ | ✅ | ❌ 双倍 |
| 高频刷新 UI（记录实时页 1s tick、曲线拖动） | ✅ 直接 | 尚可（需优化） | ✅ |
| GPS/后台/地图深度定制 | 需 MethodChannel 桥接 | 需 Native Module 桥接 | 原生直连 |
| BLE/健康（M3） | flutter_blue_plus / health 插件成熟 | 插件齐但深度弱 | 最强 |
| 单人开发效率 | 高 | 中高 | 低 |
| 最大风险 | **地图/后台两类原生桥接的坑** | 同左 + 长列表性能 | 工作量 |

**建议**：Flutter（stable 最新 LTS）+ 原生侧封装两张"王牌"：
- **地图**：不依赖高德官方 Flutter 插件的成熟度，自建 `PlatformMapView`（原生 MapView + Flutter 覆盖视图层画自绘轨迹/标记）；
- **后台记录**：原生前台服务/位置管理器 + Flutter Engine 后台存活策略（iOS 位置更新保活；Android 前台服务 + 通知）。

**回退触发**：若首个 POC（§12-P1/P2）暴露"原生↔Flutter 数据吞吐/存活"不可控，则改为**原生双端**（iOS 优先，Android 移植）——这是本方案唯一可能导致返工的技术风险，先花 1~2 天 POC 打掉。

### 2.2 选型明细（建议默认，可改）

| 领域 | 方案 | 备注 |
|---|---|---|
| 语言/UI | Dart/Flutter | 状态管理用 Riverpod（或 Bloc，选一后固定） |
| 本地库 | Drift（SQLite，类型安全）+ 内存态单例 | 事务原子写（§6 可靠性） |
| 定位（记录） | 原生位置管理器封装：iOS CoreLocation（allowsBackground+显著变化兜底）/ Android FusedLocation 前台服务 | 采样 1s/3s/5s/10s 档位 |
| 地图（M1 展示层） | 高德（国内默认）原生 SDK；OSM/Mapbox 走同一抽象（M2） | 双包名双 Key |
| 轨迹渲染 | Flutter 侧自绘折线/标记 → 叠加在原生地图上层或绘制为地图 polyline | 全 App 统一 `TrackPainter` |
| 图表（统计） | 自绘（CustomPaint）柱状/折线/热力 | 避免图表库体积，性能自查达标 |
| 状态持久化 | Drift + session 草稿表 | 崩溃恢复 |
| 代码规范 | 固定：文件夹结构、分层、单测点 | 见 §3 |

---

## 3. 仓库与模块划分（单一 App 仓库，包内分层）

```
lib/
├─ main.dart / app.dart（路由 + 全局 ProviderScope）
├─ core/            # 无业务依赖的地基
│  ├─ di.dart        # 服务注册
│  ├─ store/         # Drift 连接、migration、version
│  ├─ unit/          # 单位换算（km/mi 全局唯一入口）
│  └─ time/          # 时区/周起始/格式化
├─ domain/           # 业务模型与规则（不 import UI）
│  ├─ activity/      # Activity/Lap/聚合聚合函数 AggregateService
│  ├─ route/         # Route 模型、手绘草稿
│  ├─ stats/         # 周期/热力/趋势/PR（含窗口切片算法）
│  ├─ record/        # SessionMachine（状态机）＋ GPS 采集
│  └─ device/        # 外设抽象接口（M3 实现，先给空壳）
├─ data/             # Drift 表定义 + DAO + migration
├─ platform/         # MethodChannel：MapView / Location / ForegroundService / BLE(M3)
├─ ui/               # 页面与组件
│  ├─ home/ map/ record/ me/ stats/ activities/  # 每页一个 feature 目录
│  ├─ shared/        # 主题token、banner、chips、track画布等复用组件
│  └─ nav/           # 底部Tab + 子页栈（首页 Tab 内 统计/列表/详情子页）
└─ test/             # 单测：聚合口径、状态机、单位换算
```

依赖方向硬约束：`ui → domain ← data`，`platform` 只被 `domain/record` 与 `ui/map` 引用；禁止 domain 引用 UI。

---

## 4. 本地数据模型（Drift/SQLite 草案）

| 表 | 关键列 | 说明 |
|---|---|---|
| `activities` | id, name, type, sport_type, start_at, end_at, duration_s, moving_s, distance_m, avg_speed_mps, max_speed_mps, elev_gain_m, elev_loss_m, hr_avg, hr_max, kcal, source, weather_json, note, route_id?, device_json, app_version | 保存即终稿（不可变记录，编辑只改元数据） |
| `track_points` | activity_id, t_ms, lat*1e7, lon*1e7, alt_cm, speed_mmps, hr, cad, power, hdop, flags | 主键(activity_id,t_ms)；落库抽稀（§7）；时间序列表 |
| `laps` | activity_id, idx, start_t, end_t, dist_m, elev_m | 自动/手动计圈 |
| `drafts` | id, type, started_at, raw_json(累计数据) | 崩溃恢复唯一权威（双写策略 §7） |
| `routes` | id, name, kind, dist_m, elev_m, polyline_json, created_at, last_used_at, source, offline_region_id | M1 手绘/转存；M2 规划 |
| `settings` | key, value | 单值 KV（unit/defaultType/autoPause/autoLapKm/mapStyle/sampling…） |
| `device_profiles` | id, kind, name, address, params | M3 用，先建表 |
| `summary_cache` | period_kind, bucket_key, km, min, ele, cnt | **聚合缓存**：写入/删除活动时增量更新，统计页零扫描 |

迁移：Drift `schemaVersion` + 每条 migration 带降级说明；`drafts` 与 `summary_cache` 属易失/重建数据，migration 可安全重建。

---

## 5. 公共聚合服务（口径同源的关键）

`AggregateService`（domain/stats）是**唯一**数据出口，供首页概览、统计页、我的总览共用：

```
Future<PeriodStats> sum(Period p)            // {cnt,km,min,ele} 读 summary_cache
Future<List<DayKm>>   lastDays(7)            // 近7天（ST-04）
Future<List<BucketKm>> trend({w8|m6})        // ST-12（柱+累积共用）
Future<HeatCell[]>    heatmap(month)         // ST-11（距离→色阶）
List<RecordItem>      personalRecords()      // ST-06：最远/最长/爬升/均速
List<RecordItem>      windowRecords([10,50,100]) // 轨迹滚动切片（P0）
```

约束：
- 所有数值显示只经 `unit` 换算一次；
- 删除/导入/保存活动 → `EventBus` 广播 → 清/更 summary_cache 对应桶 → 各页重建；
- 单测「同一数据集首页/我的/统计结果逐位相等」（A-ST-03 自动化版）。

---

## 6. 记录会话状态机与后台

### 6.1 状态机（单例 `SessionMachine`，UI 只订阅）
状态：`idle → preparing(gps warm) → recording ⇄ paused → summary → saved/discarded`
事件：`start / pause / resume / lap / finish / discard / appKilled / draftRecover / routing(轻导航)`。
事件守卫：全 App 唯一会话（防双会话）；`drafts` 为崩溃后的唯一事实源。

### 6.2 双平台后台记录
- **iOS**：CoreLocation `startUpdatingLocation` + `allowsBackgroundLocationUpdates=YES`（Info.plist 声明后台定位用途）+ 常驻本地通知；暂停时降频 `startMonitoringSignificantLocationChanges`。
- **Android**：前台服务 `type=location`（manifest 声明 + 运行时通知渠道）；ROM 引导（小米/华为/OPPO/vivo）图文 Step 存入"后台与权限引导"页。
- 采样节流由原生侧按档位（1/3/5/10s）透传，UI 不阻塞。

### 6.3 崩溃恢复（RCD-07）
双写策略：会话数据每 5s（或每 1km）增量写 `drafts`（事务）；结束保存时把 `drafts` 与 `activities/track_points/laps` 同事务落库后删除草稿——保证"要么无、要么完整"。

---

## 7. 轨迹数据链路

```
GPS 原生流(1s) → platform 桥 → domain/record Collector
  → 去抖/静止过滤（速度<阈值不计里程；漂移剔除）
  → 内存 RingBuffer(当前段) + 落库节流（每 10s 或 1km 追加一次，事务）
保存：完整轨迹 → 抽稀算法（Douglas-Peucker 容差自适应 2~5m + 时间插值）
     → 原子写 activities + track_points + laps + summary_cache 更新
```
- 采样档 1s 全量只存在于会话期内存；落库即抽稀（§6 主文档存储要求）；
- `track_points` 用整型坐标压缩体积（lat/lon ×1e7、alt cm、speed mm/s）。

---

## 8. 地图抽象与共享轨迹渲染

`MapEngine` 接口（core 层定义，禁止业务 import 厂商类）：
```
load(region, style) / cameraTo(center,zoom) / addPolyline(points,{speedColor}) /
addMarker(pos,kind) / removeAllOverlays / onTap / isOfflineRegionLoaded
```
- 适配器：`AmapEngine`（M1，双端原生）、`OsmEngine/MapboxEngine`（M2）；引擎切换靠 UserSettings.mapStyle+region 路由；
- **共享轨迹渲染**：`TrackPainter`（画白描边橙主线、按速度着色、起终点）一套实现供：首页缩略、地图主图、路线详情、活动详情、记录实时页；
- M1 POC：验证原生地图瓦片 + Flutter overlay 双端帧率（真机 60fps 目标）。

---

## 9. 权限与后台合规清单（M0 骨架一并做）

| 平台 | 项 |
|---|---|
| iOS | Info.plist：`NSLocationWhenInUseUsageDescription`、`NSLocationAlwaysAndWhenInUseUsageDescription`、`UIBackgroundModes=location`；App Store 用途说明文案（含后台定位） |
| Android | 权限：ACCESS_FINE/COARSE、FOREGROUND_SERVICE、FOREGROUND_SERVICE_LOCATION、POST_NOTIFICATIONS；前台服务 type 声明 |
| 双端 | 定位/蓝牙/通知"即用即申请"文案模板（与 PRD 文案表一致）；ROM 引导图文 |

---

## 10. M1 任务拆分与排期（单人）

| 编号 | 任务 | 估时 | 依赖 | 验收出点 |
|---|---|---|---|---|
| W0.1 | 工程脚手架/主题 token/路由壳/Tab | 2d | — | 双端空壳跑通 |
| W0.2 | Drift 建表 + migration + settings | 2d | W0.1 | schema 单测 |
| W0.3 | 权限申请流程 + 用途文案 | 1d | W0.1 | 双端授权链路 |
| W0.4 | **POC：地图瓦片 + 轨迹 overlay 双端真机** | 2d | W0.1 | 60fps 达标 |
| W0.5 | **POC：后台记录（锁屏 10min）+ 崩溃草稿** | 3d | W0.2/0.3 | 轨迹连续/草稿可恢复 |
| W1.1 | AggregateService + summary_cache + 单测 | 3d | W0.2 | 口径一致自动化 |
| W1.2 | 记录准备页/实时页/摘要（RC-01~15） | 5d | W0.3/0.5 | 闭环+拦截 |
| W1.3 | 轻导航预载（RC-17，routeId） | 1.5d | W1.2 | 沿路线记录 |
| W1.4 | 首页（含横幅/草稿条/概览） | 3d | W1.1/1.2 | HP 验收 |
| W1.5 | 地图·路线页（MP-01~10 子集，手绘） | 4d | W0.4/1.3 | 路线库闭环 |
| W1.6 | 统计页（ST-01~09/11/12 + 窗口PR） | 4d | W1.1 | STA P0 全量 |
| W1.7 | 活动列表/详情（AL/AD M1 部分） | 4d | W1.1/0.4 | 死路闭合 |
| W1.8 | 我的（总览+入口） | 1.5d | W1.1 | ME-01/03 |
| W1.9 | 联调/走查/真机耗电校准 | 2d | W1.x | M1 验收门 |

合计 ≈ 6–7 周（含缓冲），与母文档 §12（5–7 周）一致。

---

## 11. M1 验收门与风险清单

**验收门**（达成才出 M1）：
1. 记录闭环：开始→10min→暂停→结束保存→列表/详情/首页/统计四处数字一致；
2. 强杀恢复草稿三操作可用；锁屏 10min 轨迹连续且耗电 ≤ 目标；
3. 统计页热力图/趋势/10·50·100 与手算一致；
4. 首页/地图/记录/我的/统计/活动全部入口无死路。

**风险与缓解**

| 风险 | 等级 | 缓解 |
|---|---|---|
| Flutter×原生地图/后台桥接不可控 | 高 | W0.4/W0.5 先行 POC，失败即回退原生双端（§2.1） |
| 厂商骑行规划接口（M2 依赖） | 中 | M1 内仅做探测 Demo（母文档 #15），不阻塞 M1 |
| 国内 ROM 后台杀进程 | 中 | W0.5 在小米/华为真机验证 + 引导页 |
| 电量超标 | 中 | 档位降频 + 真机校准（§6 主文档） |
| iOS 后台定位审核被拒 | 中 | 用途声明文案一次写对 + 预审材料 |
| 聚合口径漂移 | 低 | AggregateService 单测锁口径 |

---

## 12. 建议先行 POC（顺序，solo 最短路径）

1. **P1 · 地图 POC**（1~2 天）：原生高德 MapView + Flutter 自绘轨迹 overlay，双端帧率；
2. **P2 · 后台记录 POC**（2~3 天）：锁屏连续记录 + 通知回跳 + 强杀草稿；
3. **P3 · 数据库 POC**（1 天）：Drift 万条 track_points 查询/抽稀性能 + summary_cache 增量；
4. P4 · BLE 扫描（M3 前选做，1 天）——不阻塞 M1。
P1/P2 任一不过 → 触发选型回退决策（§2.1）。

---

## 13. 待决策 / TBD

| # | 问题 | 建议 |
|---|---|---|
| T-1 | Flutter vs 原生最终裁决 | 先跑 P1/P2 POC，按 §2.1 回退条件定 |
| T-2 | 状态管理 Riverpod / Bloc | Riverpod（样板少、易测） |
| T-3 | 统计图表自绘 vs 轻量库 | 自绘（本项目图表形状有限） |
| T-4 | 轨迹落库抽稀容差档位 | 2~5m 自适应，实现期按存储量校准 |
| T-5 | 会话草稿双写间隔 | 5s 或 1km 先到为准 |
| T-6 | 是否需要 CI（单人自用） | 轻量：`dart analyze` + 单测钩子即可 |
| T-7 | 目标设备最低版本（联调基线） | iOS 15+ / Android 8.0+，双端各借 1 台真机定基线 |

---

*本文档为 v1.0 技术草案；先跑 §12 三个 POC，随后可基于 POC 结果固化为 v1.1 并进入编码。*
