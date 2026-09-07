# 跋涉（Basho）骑行 App —— 工程仓库

> 本地优先的骑行记录 App。需求/PRD/原型/技术方案见各 Markdown（根目录），源码将位于 `app/`（Flutter，项目名 `basho`）。

## 目录

| 路径 | 内容 |
|---|---|
| `*.md`（根目录） | 母文档 v0.3、页面 PRD×6、审计报告×2、M0/M1 技术方案 |
| `prototype/` | 可交互 HTML 原型（v1.6，`python3 -m http.server` 预览） |
| `app/` | Flutter 工程（M0 起逐步构建） |
| `.staging/app/` | M0 源码暂存区（待覆写进 `app/`） |
| `.tools/` | 本沙箱内的 Flutter SDK 安装目录（**不提交 git**） |

## 在本地开发机复现（用户环境）

前提：已安装 Flutter stable（含 Android/iOS 工具链），命令：

```bash
# 1. 生成双端工程（首次）
flutter create --project-name basho --org com.basho --platforms=android,ios app

# 2. 若已有 .staging/app（M0 暂存），覆写其 lib/ 与 test/
cp -r .staging/app/lib app/lib
cp -r .staging/app/test app/test
# （保留 flutter create 生成的 pubspec.yaml / analysis_options.yaml）

# 3. 取依赖、静态检查、跑测试
cd app && flutter pub get && flutter analyze && flutter test

# 4. 运行
flutter run          # 连接设备/模拟器；缺省为当前平台
```

> 说明：`.staging/` 仅为 M0 起步的源码暂存，工程稳定后源码直接维护在 `app/lib`、`app/test`，删除 `.staging`。

## 本沙箱内工具链备忘（CI/无 GUI 环境）

- 沙箱无 root/unzip：Flutter SDK 通过 codeload tar.gz + Python `zipfile` 解压；
  `unzip` 缺失以 `.tools/bin/unzip`（python 转调 shim）覆盖 PATH。
- 每次执行前：
  `export PATH="$PWD/.tools/bin:$PWD/.tools/flutter/bin:$PATH"`
  `export PUB_CACHE="$PWD/.tools/pub-cache"`

## 架构速览（M0/M1 技术方案 §3）

```
lib/
├─ core/   单位换算、日历周期工具
├─ domain/ stats 聚合内核 · record 会话状态机 · maps 引擎抽象
├─ data/   Drift 表/DAO（M0 后续引入）
├─ platform/ 原生通道（地图/定位/前台服务）
├─ ui/     四文字Tab壳 + 首页/地图/记录/我的 + 统计/活动子页
└─ theme/  浅色主题 token（白底/橙 #fc4c02/深橙 #d64400）
```
