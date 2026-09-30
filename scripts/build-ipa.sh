#!/bin/bash
# Archive and export an IPA.
#   ./scripts/build-ipa.sh                  # development IPA
#   ./scripts/build-ipa.sh adhoc            # ad-hoc IPA
#   ./scripts/build-ipa.sh check            # print the signing that would be used
#   TEAM_ID=XXXXXXXXXX ./scripts/build-ipa.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
METHOD="${1:-development}"
SIGNING_FILE="$ROOT/Config/Signing.xcconfig"

read_xc() {
  local key="$1"
  local line=""
  if [[ -f "$SIGNING_FILE" ]]; then
    line=$(grep -E "^${key}[[:space:]]*=" "$SIGNING_FILE" | head -1 || true)
  fi
  line="${line#*=}"
  printf '%s' "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//;s/^"//;s/"$//'
}

"$ROOT/scripts/sync-config.sh"
"$ROOT/scripts/sync-version.sh"

TEAM_ID="${TEAM_ID:-$(read_xc DEVELOPMENT_TEAM)}"
CODE_SIGN_STYLE="${CODE_SIGN_STYLE:-$(read_xc CODE_SIGN_STYLE)}"
CODE_SIGN_STYLE="${CODE_SIGN_STYLE:-Automatic}"
CODE_SIGN_IDENTITY="${CODE_SIGN_IDENTITY:-$(read_xc CODE_SIGN_IDENTITY)}"
PROFILE_SPECIFIER="${PROVISIONING_PROFILE_SPECIFIER:-$(read_xc PROVISIONING_PROFILE_SPECIFIER)}"
BUNDLE_ID=$(grep -E '^PRODUCT_BUNDLE_IDENTIFIER[[:space:]]*=' "$ROOT/Config/App.xcconfig" | head -1 | cut -d= -f2- | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

if [[ ! "$TEAM_ID" =~ ^[A-Za-z0-9]{10}$ ]]; then
  echo "还没有可用的签名。模拟器可以直接运行，真机和 IPA 需要以后补签名。" >&2
  echo "补签名：复制 Config/Signing.xcconfig.example 为 Config/Signing.xcconfig，填入 10 位 DEVELOPMENT_TEAM。" >&2
  echo "步骤见 README「以后补签名证书」。确认无误后再执行 ./scripts/build-ipa.sh check" >&2
  exit 1
fi

case "$CODE_SIGN_STYLE" in
  Automatic|automatic) CODE_SIGN_STYLE="Automatic" ;;
  Manual|manual) CODE_SIGN_STYLE="Manual" ;;
  *)
    echo "CODE_SIGN_STYLE 只能是 Automatic 或 Manual，当前是: $CODE_SIGN_STYLE" >&2
    exit 1
    ;;
esac

if [[ "$CODE_SIGN_STYLE" == "Manual" ]]; then
  if [[ -z "$CODE_SIGN_IDENTITY" || -z "$PROFILE_SPECIFIER" ]]; then
    echo "手动签名需要在 Config/Signing.xcconfig 里同时填写 CODE_SIGN_IDENTITY 和 PROVISIONING_PROFILE_SPECIFIER。" >&2
    exit 1
  fi
fi

case "$METHOD" in
  development) EXPORT_TEMPLATE="$ROOT/ExportOptions.plist" ;;
  adhoc|ad-hoc) EXPORT_TEMPLATE="$ROOT/ExportOptions-adhoc.plist" ;;
  check) EXPORT_TEMPLATE="$ROOT/ExportOptions.plist" ;;
  *)
    echo "未知导出方式: $METHOD （可选 development、adhoc 或 check）" >&2
    exit 1
    ;;
esac

mkdir -p "$ROOT/build"
EXPORT_PLIST="$ROOT/build/ExportOptions.plist"
python3 - "$EXPORT_TEMPLATE" "$EXPORT_PLIST" "$TEAM_ID" "$CODE_SIGN_STYLE" "$BUNDLE_ID" "$PROFILE_SPECIFIER" <<'PY'
import plistlib
import sys

src, dest, team, style, bundle_id, profile = sys.argv[1:]
with open(src, "rb") as handle:
    data = plistlib.load(handle)
data["teamID"] = team
data["signingStyle"] = "manual" if style == "Manual" else "automatic"
if style == "Manual":
    data["provisioningProfiles"] = {bundle_id: profile}
with open(dest, "wb") as handle:
    plistlib.dump(data, handle)
PY

if [[ "$METHOD" == "check" ]]; then
  echo "签名检查通过"
  echo "TEAM_ID=$TEAM_ID"
  echo "CODE_SIGN_STYLE=$CODE_SIGN_STYLE"
  echo "BUNDLE_ID=$BUNDLE_ID"
  if [[ "$CODE_SIGN_STYLE" == "Manual" ]]; then
    echo "CODE_SIGN_IDENTITY=$CODE_SIGN_IDENTITY"
    echo "PROVISIONING_PROFILE_SPECIFIER=$PROFILE_SPECIFIER"
  fi
  echo "导出配置: $EXPORT_PLIST"
  exit 0
fi

if ! command -v xcodegen >/dev/null 2>&1; then
  echo "未找到 xcodegen。先执行: brew install xcodegen" >&2
  exit 1
fi
if ! xcode-select -p 2>/dev/null | grep -q "Xcode.app"; then
  echo "当前只有 Command Line Tools。请先安装完整版 Xcode，并执行: sudo xcode-select -s /Applications/Xcode.app/Contents/Developer" >&2
  exit 1
fi

xcodegen generate --spec "$ROOT/project.yml"

ARCHIVE="$ROOT/build/XinJi28.xcarchive"
EXPORT_DIR="$ROOT/build/ipa"
if [[ "$METHOD" == "development" ]]; then
  CONFIGURATION="Debug"
  DEST_NAME="XJ28-debug.ipa"
else
  CONFIGURATION="Release"
  DEST_NAME="XJ28-release.ipa"
fi

rm -rf "$ARCHIVE" "$EXPORT_DIR"
mkdir -p "$ROOT/build"

SIGN_ARGS=(DEVELOPMENT_TEAM="$TEAM_ID" CODE_SIGN_STYLE="$CODE_SIGN_STYLE")
if [[ "$CODE_SIGN_STYLE" == "Manual" ]]; then
  SIGN_ARGS+=(CODE_SIGN_IDENTITY="$CODE_SIGN_IDENTITY" PROVISIONING_PROFILE_SPECIFIER="$PROFILE_SPECIFIER")
fi

xcodebuild \
  -project "$ROOT/XinJi28.xcodeproj" \
  -scheme XinJi28 \
  -configuration "$CONFIGURATION" \
  -destination "generic/platform=iOS" \
  -archivePath "$ARCHIVE" \
  "${SIGN_ARGS[@]}" \
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

DEST="$EXPORT_DIR/$DEST_NAME"
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
