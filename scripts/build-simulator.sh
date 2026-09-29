#!/bin/bash
# Compile the shell for the iOS Simulator. Does not produce an installable IPA.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
"$ROOT/scripts/sync-config.sh"
"$ROOT/scripts/sync-version.sh"

if ! command -v xcodegen >/dev/null 2>&1; then
  echo "未找到 xcodegen。先执行: brew install xcodegen" >&2
  exit 1
fi
if ! xcode-select -p 2>/dev/null | grep -q "Xcode.app"; then
  echo "当前只有 Command Line Tools。请先安装完整版 Xcode。" >&2
  exit 1
fi

xcodegen generate --spec "$ROOT/project.yml"

DESTINATION="${DESTINATION:-platform=iOS Simulator,name=iPhone 16}"
xcodebuild \
  -project "$ROOT/XinJi28.xcodeproj" \
  -scheme XinJi28 \
  -configuration Debug \
  -destination "$DESTINATION" \
  -derivedDataPath "$ROOT/build/DerivedData" \
  CODE_SIGNING_ALLOWED=NO \
  build

echo "模拟器编译完成: $ROOT/build/DerivedData"
