#!/bin/bash
# Archive and export an IPA.
#   ./scripts/build-ipa.sh                  # development IPA, needs TEAM_ID or Config/Signing.xcconfig
#   ./scripts/build-ipa.sh adhoc            # ad-hoc IPA
#   TEAM_ID=XXXXXXXXXX ./scripts/build-ipa.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
METHOD="${1:-development}"

"$ROOT/scripts/sync-config.sh"
"$ROOT/scripts/sync-version.sh"

if ! command -v xcodegen >/dev/null 2>&1; then
  echo "未找到 xcodegen。先执行: brew install xcodegen" >&2
  exit 1
fi
if ! xcode-select -p 2>/dev/null | grep -q "Xcode.app"; then
  echo "当前只有 Command Line Tools。请先安装完整版 Xcode，并执行: sudo xcode-select -s /Applications/Xcode.app/Contents/Developer" >&2
  exit 1
fi

TEAM_ID="${TEAM_ID:-}"
if [[ -z "$TEAM_ID" && -f "$ROOT/Config/Signing.xcconfig" ]]; then
  TEAM_ID=$(grep -E '^DEVELOPMENT_TEAM' "$ROOT/Config/Signing.xcconfig" | head -1 | cut -d= -f2 | tr -d '[:space:]')
fi
if [[ -z "$TEAM_ID" ]]; then
  echo "打包 IPA 需要 Apple 开发者 Team ID。" >&2
  echo "复制 Config/Signing.xcconfig.example 为 Config/Signing.xcconfig，填入 DEVELOPMENT_TEAM，或运行时设置 TEAM_ID。" >&2
  exit 1
fi

case "$METHOD" in
  development) EXPORT_PLIST="$ROOT/ExportOptions.plist" ;;
  adhoc|ad-hoc) EXPORT_PLIST="$ROOT/ExportOptions-adhoc.plist" ;;
  *)
    echo "未知导出方式: $METHOD （可选 development 或 adhoc）" >&2
    exit 1
    ;;
esac

xcodegen generate --spec "$ROOT/project.yml"

ARCHIVE="$ROOT/build/XinJi28.xcarchive"
EXPORT_DIR="$ROOT/build/ipa"

rm -rf "$ARCHIVE" "$EXPORT_DIR"
mkdir -p "$ROOT/build"

xcodebuild \
  -project "$ROOT/XinJi28.xcodeproj" \
  -scheme XinJi28 \
  -configuration Release \
  -destination "generic/platform=iOS" \
  -archivePath "$ARCHIVE" \
  DEVELOPMENT_TEAM="$TEAM_ID" \
  CODE_SIGN_STYLE=Automatic \
  archive

xcodebuild \
  -exportArchive \
  -archivePath "$ARCHIVE" \
  -exportPath "$EXPORT_DIR" \
  -exportOptionsPlist "$EXPORT_PLIST"

IPA=$(find "$EXPORT_DIR" -name '*.ipa' | head -1)
if [[ -z "$IPA" ]]; then
  echo "导出完成但没有找到 ipa 文件" >&2
  exit 1
fi

if [[ "$METHOD" == "development" ]]; then
  DEST="$EXPORT_DIR/新纪28-debug.ipa"
else
  DEST="$EXPORT_DIR/XJ28-release.ipa"
fi
mv "$IPA" "$DEST"

python3 - "$ROOT/version.properties" <<'PY'
import sys
path = sys.argv[1]
lines = open(path, encoding="utf-8").read().splitlines()
out = []
for line in lines:
    if line.startswith("VERSION_PATCH="):
        out.append(f"VERSION_PATCH={int(line.split('=',1)[1]) + 1}")
    elif line.startswith("VERSION_CODE="):
        out.append(f"VERSION_CODE={int(line.split('=',1)[1]) + 1}")
    else:
        out.append(line)
open(path, "w", encoding="utf-8").write("\n".join(out) + "\n")
PY
"$ROOT/scripts/sync-version.sh" >/dev/null
echo "IPA: $DEST"
echo "版本号已自动递增，下次打包见 version.properties"
