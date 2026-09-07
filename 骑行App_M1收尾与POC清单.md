# M1 收尾与 POC 清单（跋涉 · 骑行 App）

| 项 | 内容 |
|---|---|
| 日期 | 2026-09-07 |
| 状态 | M1 核心闭环代码已落地并通过 Flutter 工具链验证 |
| 依据 | 《骑行App_M0M1技术方案_v1.0.md》§10~§12 |

---

## 一、M1 已完成（代码 + 验证通过）

| 模块 | 交付 | 验证 |
|---|---|---|
| 四 Tab 导航（首页/地图/记录/我的，纯文字） | `ui/nav/root_shell.dart` | widget 冒烟 ✅ |
| 主题 token（浅色） | `theme/app_theme.dart` | ✅ |
| 领域纯逻辑 | 单位/calendar/统计内核/会话状态机/地图抽象 | `analyze` 0 · 单测 ✅ |
| 数据层（Drift v2） | activities/track_points/laps/drafts/summary_cache/settings/**routes** + 迁移 v1→v2 | 集成测试 ✅ |
| 公共聚合服务 | `AggregateService` + `ridesProvider`（唯一数据出口） | 首页/统计/我的/详情共用 ✅ |
| 首页概览/最近活动/空态 | 真数据 + 今日/本周/本月分段 | ✅ |
| 记录页（类型/自动暂停/自动计圈/计时/暂停/保存） | 会话状态机 UI | 闭环测试① ✅ |
| 草稿恢复（RCD-07） | RecordPage 落库草稿 + 继续横幅 | ✅ |
| 活动列表/详情 + 删除 | `activity_list/detail_page` | ✅ |
| 统计 P0 | 周期/近7天/近6月趋势/日历热力图/个人纪录(含10/50/100km) | ✅ |
| 地图·路线（纯数据） | Routes + RouteRepository + 手绘编辑器 + 列表/缩略图/删除 | 测试② ✅ |
| 我的（真实累计 + 入口） | 总里程/时长/爬升/次数 | ✅ |

**整体质量门**：`flutter analyze` **No issues**；`flutter test` **15/15 全绿**（真实 Flutter 3.47.2 toolchain）。
**可运行性**：用户已在 WSL 成功 `flutter run -d linux`（构建 bundle 成功）且通过 `flutter run -d web-server` 在浏览器看到 UI。

---

## 二、M1 内待办（需真机/真实 SDK，超出沙箱，须在真机环境完成）

### 2.1 地图真实渲染（对应技术方案 §12 P1 地图 POC）
- [ ] 接入高德（国内）/OSM·Mapbox（海外）原生地图；验证 Flutter overlay 轨迹自绘双端帧率 ≥ 60fps（真机）
- [ ] 用 `domain/maps/MapEngine` 抽象落地 `AmapEngine`/`OsmEngine` 适配器，替换手绘占位画布
- [ ] 首页/活动详情缩略图、记录实时页复用同一 `TrackPainter`（当前用画布折线占位）
- 验收：真机地图瓦片渲染 + 轨迹线流畅；标准/卫星切换记忆

### 2.2 后台/锁屏/耗电（真机验证）
- [ ] iOS：CoreLocation 后台定位 + 用途声明（Info.plist `UIBackgroundModes=location` + 文案）
- [ ] Android：前台服务 `type=location` + ROM 引导（小米/华为/OPPO/vivo）
- [ ] 锁屏 10min 轨迹连续无跳变；1s 采样 1h 耗电 ≤15%（§6 NFR）
- 验收：记录中切后台/锁屏仍记录，常驻通知回跳

### 2.3 数据链路增强（代码已预留）
- [ ] 轨迹点落库（`track_points` 表已建，记录流接入 + 抽稀/去抖）
- [ ] `laps` 计圈明细落库、`summary_cache` 增量刷新（当前全量重算）
- 验收：保存后详情页出现轨迹线/计圈分段

### 2.4 iOS/商店审核材料
- [ ] 后台定位用途说明、隐私政策（上架前必做，§9 合规）

---

## 三、M2 及以后（超出本目标，列出不展开）
完整导航（turn-by-turn/自动规划/离线）、导入导出（.fit/.gpx）、外设（BLE/健康平台，待真机）、账号/云同步、社交/商业化。

---

## 四、本目标验收口径对照

| 验收口径 | 结果 |
|---|---|
| 代码可 analyze | ✅ No issues |
| 代码可 test | ✅ 15/15 |
| 记录→保存→列表/详情→统计口径一致 | ✅（共用 AggregateService/ridesProvider，测试①） |
| 首页概览 / 四 Tab 导航 | ✅ |
| 地图抽象接口 / 草稿恢复预留 | ✅（`domain/maps/MapEngine`；RecordPage 草稿继续） |
| 可在本机/用户环境运行 | ✅（用户已在 WSL 构建 + web 预览成功） |

> 说明：**真实地图渲染、后台/锁屏真机、轨迹点落库** 属 M1 内但依赖真机/原生 SDK 的条目，已在本清单 2.1~2.3 明确验收口径；其**代码层预留**（表结构、MapEngine 抽象、会话状态机、草稿）已在本目标内完成。
