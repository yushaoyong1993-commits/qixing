#!/usr/bin/env bash
# M0 一键构建：flutter create + 覆写 staged 源码 + pub get + analyze + test
# 用法（SDK 装好后，在工作区根目录）：
#   export PATH="$PWD/.tools/flutter/bin:$PATH"
#   bash tool/m0_bootstrap.sh [run]
#   [run] 额外执行 flutter run -d linux（WSLg 桌面预览）
set -euo pipefail
cd "$(dirname "$0")/.."
ROOT="$PWD"

command -v flutter >/dev/null 2>&1 || { echo "flutter 不在 PATH：请先 export PATH=\"$ROOT/.tools/flutter/bin:\$PATH\""; exit 1; }

# 1) 生成双端工程（若不存在）
if [ ! -d app ]; then
  flutter create --project-name basho --org com.basho \
    --platforms=android,ios,linux app
fi

# 2) 覆写 M0 源码（保留模板 pubspec/analysis_options，替换 lib 与 test）
rm -rf app/lib app/test
cp -r .staging/app/lib app/lib
cp -r .staging/app/test app/test
mkdir -p app/tool && cp .staging/app/tool/pure_selfcheck.dart app/tool/ 2>/dev/null || true
rm -f app/test/widget_test.dart
echo "→ 源码已覆写 (lib/test)"

# 3) 取依赖 & 静态检查 & 测试
cd app
flutter pub get
echo "== flutter analyze =="
flutter analyze
echo "== flutter test =="
flutter test

if [ "${1:-}" = "run" ]; then
  flutter config --enable-linux-desktop >/dev/null 2>&1 || true
  echo "== flutter run -d linux (WSLg) =="
  flutter run -d linux
fi
echo "M0 done."
