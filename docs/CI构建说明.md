# CI 构建说明（云端出 APK，本机零负担）

> 目的：把「编译打包」这件重活交给云端临时机器，你的电脑只负责写代码与跑测试。
> 配置文件：`.github/workflows/android.yml`

---

## 一、原理（一图看懂）

```
你的 WSL（轻活）                 GitHub 云端 Runner（重活，用完即弃）
编辑代码 → git push   ─────────▶  ① 拉代码
                                  ② 装 JDK17 + Flutter 3.47.2 + Android SDK36 + NDK
                                  ③ flutter pub get
                                  ④ flutter analyze + flutter test（质量门）
                                  ⑤ flutter build apk --release（arm64）
                                  ⑥ 上传产物 basho-release-apk
                                        │
你在浏览器下载 APK   ◀──────────────────┘
        │
        └─ 传到手机安装（或 adb install）
```

- Runner 是**临时虚拟机**（约 4 核 / 16 GB），跑完即销毁：不占你电脑 CPU/内存，也不会出现本地那种「缓存被写坏 / 锁残留」问题；
- 工作流分两个 job：`quality`（分析 + 全量测试）→ 通过后才 `apk`（出包），保证不会产出坏包。

---

## 二、首次准备：把仓库推到 GitHub（约 3 分钟）

1. 在 https://github.com/new 新建一个仓库（**建议选 Private**；若选 Public，Actions 时长完全免费且不限量）。
2. 记下仓库地址，例如 `https://github.com/<你的用户名>/basho.git`。
3. 在 WSL 里执行（仓库已经在本地做了 63 次提交）：

```bash
cd ~/dsh_workspace/qixing
git remote add origin https://github.com/<你的用户名>/basho.git
git branch -M main
git push -u origin main
```
> 首次 push 需要认证：推荐用 **Personal Access Token**（GitHub → Settings → Developer settings → Tokens (classic) → 勾选 `repo`）当作密码输入；或配置 SSH key。

推上去后，Actions 页会自动跑一次构建。

---

## 三、日常怎么用（两种方式）

### 方式 A：网页点按钮（推荐，省额度）
1. 打开仓库 → **Actions** → 左侧 **Android CI** → 右侧 **Run workflow** → 选 `main` → Run；
2. 等约 **6~12 分钟**（首次含 SDK/NDK 下载；有缓存后 5~8 分钟）；
3. 进入这次运行 → 页面底部 **Artifacts** → 下载 `basho-release-apk`（zip，内含 `app-release.apk`）。

### 方式 B：推代码自动构建
```bash
cd ~/dsh_workspace/qixing
git add -A && git commit -m "feat: xxx"
git push            # push 到 main 会自动触发
```

### 用命令行直接取回产物（可选，需要 `gh` CLI）
```bash
gh run list --limit 3                     # 看最近几次运行
gh run watch                              # 实时看进度
gh run download --name basho-release-apk --dir ~/apk
ls -lh ~/apk/app-release.apk
```

---

## 四、装到手机

```bash
cd ~/dsh_workspace/qixing/app
export PATH="$HOME/Android/Sdk/platform-tools:$PATH"
adb devices
adb -s '<设备id>' install -r ~/apk/app-release.apk
```
> 也可以把下载的 APK 直接复制到手机（微信/网盘/数据线）后点击安装，允许「未知来源」即可。

---

## 五、费用与额度（不用花钱）

| 项 | 说明 |
|---|---|
| 公开仓库 | Actions **完全免费、不限时长** |
| 私有仓库（GitHub Free） | **2,000 分钟/月**；一次构建约 6~12 分钟 → 每月可构建 **150 次以上** |
| 计费倍率 | Linux Runner = **1×**（Windows 2×、macOS 10×），本项目只用 Linux |
| 产物存储 | 已设 `retention-days: 7` 自动清理；release arm64 包约 **64 MB**，远超不了 500 MB 额度 |

**省额度小技巧**：日常用「方式 A 手动触发」，只在需要装机时才构建。

---

## 六、将来要正式签名（上架/长期使用）

目前 `app/android/app/build.gradle.kts` 的 release 用的是**调试签名**（自用没问题）。要换成正式签名：

1. 本地生成 keystore：
```bash
keytool -genkey -v -keystore ~/basho-release.jks -keyalg RSA -keysize 2048 \
  -validity 10000 -alias basho
base64 -w0 ~/basho-release.jks > ~/basho-release.jks.b64   # 转成 base64
```
2. 在 GitHub 仓库 → **Settings → Secrets and variables → Actions** 新建：
   - `KEYSTORE_BASE64`：上面 base64 内容
   - `KEYSTORE_PASSWORD`、`KEY_ALIAS`、`KEY_PASSWORD`
3. 在 workflow 里加一步解码 + 让 Gradle 使用（我可以按需补上这段）。

---

## 七、排错对照表

| 现象 | 原因 / 处理 |
|---|---|
| `quality` job 失败在 `flutter analyze` / `flutter test` | 代码或测试有问题；本地先跑一遍同样的命令确认 |
| 报 `Could not read workspace metadata` | 云端不会出现（每次全新环境）；本地出现时清 `~/.gradle/caches` 与 `app/android/.gradle` |
| 报 `Architecture.arm64e` / native-assets 失败 | 依赖里混入了与当前 SDK 不兼容的包（本项目已用 `dependency_overrides` 固定 `path_provider_foundation: 2.5.1` 规避） |
| 构建时间特别长（>15 分钟） | 首次正常；检查缓存是否命中（Actions 日志里 `Cache restored`） |
| 想改成 debug 包 | 把 `flutter build apk --release` 改成 `--debug`，并把产物路径改成 `app-debug.apk` |
| 想同时出 debug + release | 复制一份 `apk` job，或用 matrix（可按需加） |

---

## 八、本地仍需承担的部分（很轻）

```bash
cd ~/dsh_workspace/qixing/app
export ANDROID_HOME="$HOME/Android/Sdk"
export PATH="$ANDROID_HOME/platform-tools:$HOME/dsh_workspace/qixing/.tools/flutter/bin:$PATH"
export PUB_CACHE="$HOME/dsh_workspace/qixing/.tools/pub-cache"

flutter analyze     # 约 10 秒
flutter test        # 约 10 秒、61 个用例
```
这两条完全跑得动（占用 <1 GB），是日常开发的主要反馈手段；只有"出安装包"才交给云端。

---

## 九、正式签名（已接入，可选启用）

CI 支持**可选正式签名**：配置了 Secrets 就用正式 keystore，未配置则自动回退 debug 签名（构建不会失败）。

### 本地已生成的固定 release keystore
| 项 | 值 |
|---|---|
| 文件 | `~/basho-signing/basho-release.jks`（**勿提交**，已在 `.gitignore` 排除） |
| 别名 | `basho` |
| 口令 | 见 `~/basho-signing/CREDENTIALS.txt`（600 权限） |
| **SHA1**（高德 Android key 需绑定） | `88:35:81:28:73:BE:15:53:7A:D8:D1:B2:D5:29:1F:D9:AE:DF:BF:5A` |
| SHA256 | `FC:EC:52:63:30:AF:AD:7E:36:E6:DA:02:41:6D:D0:CE:7E:49:4E:82:28:A0:84:49:5D:B6:01:CD:B6:7C:81:99` |

### 在 GitHub 启用正式签名
仓库 → Settings → Secrets and variables → Actions → New repository secret：

| Secret | 取值 |
|---|---|
| `KEYSTORE_BASE64` | `base64 -w0 ~/basho-signing/basho-release.jks` 的输出 |
| `KEYSTORE_PASSWORD` | CREDENTIALS.txt 里的 storePassword |
| `KEY_ALIAS` | `basho` |
| `KEY_PASSWORD` | 同 storePassword |

### 本地启用（可选）
`app/android/key.properties`：
```properties
storeFile=/home/yushaoyong/basho-signing/basho-release.jks
storePassword=<口令>
keyAlias=basho
keyPassword=<口令>
```

### 高德原生 SDK 必须绑定 SHA1
包名 `com.basho.basho` + 签名 SHA1（上面那串）→ 加到高德控制台该 Android key 下；建议把**本地 debug keystore 的 SHA1** 也一并加上，方便真机调试。

---

## 十、地图实现（已切换为原生 SDK）

| 项 | 旧方案 | 现方案 |
|---|---|---|
| 地图渲染 | WebView + 高德 JS API | **Android 原生高德 SDK PlatformView**（`TextureMapView`） |
| 依赖 | `webview_flutter` | `com.amap.api:3dmap`（原生，Maven: maven.amap.com） |
| 白屏问题 | 切页返回时偶发 Canvas 丢失，需 `map.resize()`/重建兜底 | 原生视图，无此问题 |
| 交互 | JS 桥接、帧率偏低 | 原生手势，帧率与省电更好 |
| Dart 组件 | `AmapMapView`（已删除） | `AmapNativeView`（同构 API：render/renderNav/moveTo/fitRoute/refresh/rebuild） |
| 高德 key | Web 端 JS key | manifest `com.amap.api.v2.apikey` = **Android 平台 key**（需绑定包名+签名 SHA1） |

**真机验证前提**：高德控制台需把 `com.basho.basho` 的签名 SHA1 加到该 Android key 上（keystore SHA1 见第九章；若非正式签名，则加对应 debug keystore 的 SHA1）。

---

## 十一、B2 升级记录（Flutter 补丁升级 + 解除依赖固定）

| 项 | 变更前 | 变更后 |
|---|---|---|
| CI Flutter 版本 | 3.47.2 | **3.47.4**（stable 补丁版） |
| `dependency_overrides` | 固定 `path_provider_foundation: 2.5.1` | **已移除**（现解析为 2.6.0 + `objective_c 9.6.1`） |
| 动机 | 3.47.2 的 native-assets 工具链缺少 `Architecture.arm64e`，导致 objective_c 钩子编译失败 | CI matrix 实测：3.47.4 上 `analyze + test + build` 全绿，可安全解 pin |

**本地开发提示**：本机 SDK 仍是 3.47.2，`flutter analyze` / `flutter test` 不受影响；
但**本地打 APK** 需要把 SDK 升到 3.47.4（否则原生钩子会失败），或直接交给 CI 出包：
```bash
cd ~/dsh_workspace/qixing/.tools/flutter && git fetch --tags && git checkout 3.47.4
```
