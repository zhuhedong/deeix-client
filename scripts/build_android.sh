#!/usr/bin/env bash
#
# build_android.sh — 打包 Deeix Client 的安卓产物 (APK / AAB)
#
# 用法:
#   scripts/build_android.sh [选项]
#
# 常用示例:
#   scripts/build_android.sh                     # release APK (通用)
#   scripts/build_android.sh --split             # release APK，按 ABI 拆分（体积更小）
#   scripts/build_android.sh --aab               # release AAB（上架 Google Play 用）
#   scripts/build_android.sh --debug             # debug APK
#   scripts/build_android.sh --api https://your.domain
#   scripts/build_android.sh --aab --build-name 1.2.0 --build-number 5
#   scripts/build_android.sh --clean --install   # 先 clean，构建后安装到已连设备
#
# 说明:
#   - 默认 release 构建。若未配置 android/key.properties，release 会用 debug 密钥签名，
#     可直接侧载安装，但无法上架 Play 商店（详见文末签名说明）。
#   - 产物会复制到项目根目录的 dist/ 下，并按 版本+类型+时间戳 重命名。
#
set -euo pipefail

# ------------------------------------------------------------------ 路径设置
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

# Flutter SDK：优先用环境变量 FLUTTER_BIN，其次常见路径，最后靠 PATH。
FLUTTER_BIN="${FLUTTER_BIN:-/Users/code/development/flutter/bin}"
if [ -x "$FLUTTER_BIN/flutter" ]; then
  export PATH="$FLUTTER_BIN:$PATH"
fi
if ! command -v flutter >/dev/null 2>&1; then
  echo "✗ 找不到 flutter，可执行 export FLUTTER_BIN=/path/to/flutter/bin 后重试" >&2
  exit 1
fi

# ------------------------------------------------------------------ 默认参数
FORMAT="apk"          # apk | aab
MODE="release"        # release | debug | profile
SPLIT=false           # 仅 apk：按 ABI 拆分
DO_CLEAN=false
DO_INSTALL=false
API_URL=""
BUILD_NAME=""
BUILD_NUMBER=""
OBFUSCATE=false

usage() {
  sed -n '2,30p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
  exit 0
}

# ------------------------------------------------------------------ 解析参数
while [ $# -gt 0 ]; do
  case "$1" in
    --apk)          FORMAT="apk" ;;
    --aab|--bundle) FORMAT="aab" ;;
    --split)        SPLIT=true ;;
    --debug)        MODE="debug" ;;
    --profile)      MODE="profile" ;;
    --release)      MODE="release" ;;
    --clean)        DO_CLEAN=true ;;
    --install)      DO_INSTALL=true ;;
    --obfuscate)    OBFUSCATE=true ;;
    --api)          API_URL="${2:?--api 需要一个 URL}"; shift ;;
    --build-name)   BUILD_NAME="${2:?--build-name 需要一个版本号}"; shift ;;
    --build-number) BUILD_NUMBER="${2:?--build-number 需要一个整数}"; shift ;;
    -h|--help)      usage ;;
    *) echo "✗ 未知参数: $1（用 -h 查看帮助）" >&2; exit 1 ;;
  esac
  shift
done

# ------------------------------------------------------------------ 版本信息
APP_VERSION="$(grep -E '^version:' pubspec.yaml | head -1 | sed 's/version:[[:space:]]*//' | tr -d '\r' || true)"
APP_VERSION="${APP_VERSION:-0.0.0}"
STAMP="$(date +%Y%m%d-%H%M%S)"

# ------------------------------------------------------------------ 组装命令
BUILD_ARGS=("build")
if [ "$FORMAT" = "aab" ]; then
  BUILD_ARGS+=("appbundle")
else
  BUILD_ARGS+=("apk")
  $SPLIT && BUILD_ARGS+=("--split-per-abi")
fi
BUILD_ARGS+=("--$MODE")
[ -n "$API_URL" ]      && BUILD_ARGS+=("--dart-define=API_BASE_URL=$API_URL")
[ -n "$BUILD_NAME" ]   && BUILD_ARGS+=("--build-name=$BUILD_NAME")
[ -n "$BUILD_NUMBER" ] && BUILD_ARGS+=("--build-number=$BUILD_NUMBER")
if $OBFUSCATE && [ "$MODE" = "release" ]; then
  BUILD_ARGS+=("--obfuscate" "--split-debug-info=build/symbols")
fi

echo "──────────────────────────────────────────────"
echo "  项目      : $PROJECT_ROOT"
echo "  Flutter   : $(command -v flutter)"
echo "  版本      : $APP_VERSION"
echo "  产物      : $FORMAT ($MODE)$($SPLIT && [ "$FORMAT" = apk ] && echo ' · split-per-abi')"
[ -n "$API_URL" ] && echo "  API       : $API_URL"
if [ -f android/key.properties ]; then
  echo "  签名      : release keystore (android/key.properties)"
else
  echo "  签名      : debug 密钥（未配置 key.properties，仅可侧载）"
fi
echo "  命令      : flutter ${BUILD_ARGS[*]}"
echo "──────────────────────────────────────────────"

# ------------------------------------------------------------------ 执行构建
if $DO_CLEAN; then
  echo "▸ flutter clean"
  flutter clean
fi

echo "▸ flutter pub get"
flutter pub get

echo "▸ flutter ${BUILD_ARGS[*]}"
flutter "${BUILD_ARGS[@]}"

# ------------------------------------------------------------------ 收集产物
mkdir -p dist
DIST_FILES=()

collect() { # src -> dist/<name>
  local src="$1" name="$2"
  if [ -f "$src" ]; then
    cp -f "$src" "dist/$name"
    DIST_FILES+=("dist/$name")
  fi
}

if [ "$FORMAT" = "aab" ]; then
  collect "build/app/outputs/bundle/${MODE}/app-${MODE}.aab" \
          "deeix-client-${APP_VERSION}-${MODE}-${STAMP}.aab"
else
  if $SPLIT; then
    for abi in armeabi-v7a arm64-v8a x86_64; do
      collect "build/app/outputs/flutter-apk/app-${abi}-${MODE}.apk" \
              "deeix-client-${APP_VERSION}-${abi}-${MODE}-${STAMP}.apk"
    done
  else
    collect "build/app/outputs/flutter-apk/app-${MODE}.apk" \
            "deeix-client-${APP_VERSION}-${MODE}-${STAMP}.apk"
  fi
fi

echo ""
echo "✓ 构建完成，产物："
if [ "${#DIST_FILES[@]}" -eq 0 ]; then
  echo "  （未找到预期产物，请检查上面的构建日志）" >&2
  exit 1
fi
for f in "${DIST_FILES[@]}"; do
  size="$(du -h "$f" | cut -f1)"
  printf "  %-8s %s\n" "$size" "$PROJECT_ROOT/$f"
done

# 归档混淆符号表：反解崩溃堆栈必须用「同一次构建」的符号，且 flutter clean 会清掉
# build/symbols，因此随产物一起留存。反解命令：
#   flutter symbolize -i <stack.txt> -d dist/<symbols-dir>/app.android-arm64.symbols
if $OBFUSCATE && [ "$MODE" = "release" ] && [ -d build/symbols ]; then
  SYM_DIR="dist/symbols-${APP_VERSION}-${STAMP}"
  mkdir -p "$SYM_DIR"
  cp -f build/symbols/*.symbols "$SYM_DIR"/ 2>/dev/null || true
  echo "  符号表   $PROJECT_ROOT/$SYM_DIR/ （请与该 APK 一并妥善保存）"
fi

# ------------------------------------------------------------------ 可选安装
if $DO_INSTALL; then
  if [ "$FORMAT" = "aab" ]; then
    echo "⚠ AAB 不能直接 adb 安装，跳过 --install（如需安装请构建 APK）"
  elif command -v adb >/dev/null 2>&1; then
    APK_TO_INSTALL="${DIST_FILES[0]}"
    echo "▸ adb install -r $APK_TO_INSTALL"
    adb install -r "$APK_TO_INSTALL"
  else
    echo "⚠ 未找到 adb，跳过安装"
  fi
fi
