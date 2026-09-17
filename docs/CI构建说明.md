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
