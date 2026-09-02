#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🛫 Karu Focus Timer — Standalone macOS App Packager"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 1. Generate Icons if needed
if [ ! -f "${ROOT_DIR}/Packaging/AppIcon.icns" ]; then
    echo "🎨 Generating AppIcon.icns..."
    swift "${ROOT_DIR}/scripts/generate_app_icon.swift"
fi

# 2. Build Release Executables (App + Widgets)
echo "🔨 Compiling Karu & KaruWidgets (Release Configuration)..."
cd "${ROOT_DIR}"
swift build -c release

RELEASE_BIN="${ROOT_DIR}/.build/release/Karu"
WIDGET_BIN="${ROOT_DIR}/.build/release/KaruWidgets"

if [ ! -f "${RELEASE_BIN}" ]; then
    echo "❌ Error: Release binary not found at ${RELEASE_BIN}"
    exit 1
fi
if [ ! -f "${WIDGET_BIN}" ]; then
    echo "❌ Error: Widget binary not found at ${WIDGET_BIN}"
    exit 1
fi

# 3. Assemble .app Directory Structure
APP_BUNDLE="${ROOT_DIR}/build/Karu.app"
echo "📦 Assembling Application Bundle at ${APP_BUNDLE}..."

rm -rf "${APP_BUNDLE}"
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources"
mkdir -p "${APP_BUNDLE}/Contents/PlugIns"
mkdir -p "${ROOT_DIR}/build/dist"

# Copy App Binary
cp "${RELEASE_BIN}" "${APP_BUNDLE}/Contents/MacOS/Karu"
chmod +x "${APP_BUNDLE}/Contents/MacOS/Karu"

# Copy Info.plist & PkgInfo
cp "${ROOT_DIR}/Packaging/Info.plist" "${APP_BUNDLE}/Contents/Info.plist"
echo -n "APPLKARU" > "${APP_BUNDLE}/Contents/PkgInfo"

# Copy AppIcon.icns
if [ -f "${ROOT_DIR}/Packaging/AppIcon.icns" ]; then
    cp "${ROOT_DIR}/Packaging/AppIcon.icns" "${APP_BUNDLE}/Contents/Resources/AppIcon.icns"
fi

# Assemble Embedded Widget Extension (.appex) in Contents/Extensions (macOS 13+) and Contents/PlugIns
WIDGET_EXT_BUNDLE="${APP_BUNDLE}/Contents/Extensions/KaruWidgets.appex"
WIDGET_PLUGIN_BUNDLE="${APP_BUNDLE}/Contents/PlugIns/KaruWidgets.appex"
echo "🧩 Assembling Widget Extension at ${WIDGET_EXT_BUNDLE}..."

mkdir -p "${APP_BUNDLE}/Contents/Extensions"
mkdir -p "${APP_BUNDLE}/Contents/PlugIns"

for W_DIR in "${WIDGET_EXT_BUNDLE}" "${WIDGET_PLUGIN_BUNDLE}"; do
    mkdir -p "${W_DIR}/Contents/MacOS"
    mkdir -p "${W_DIR}/Contents/Resources"

    cp "${WIDGET_BIN}" "${W_DIR}/Contents/MacOS/KaruWidgets"
    chmod +x "${W_DIR}/Contents/MacOS/KaruWidgets"

    cp "${ROOT_DIR}/Packaging/WidgetInfo.plist" "${W_DIR}/Contents/Info.plist"
    echo -n "XPC!KARU" > "${W_DIR}/Contents/PkgInfo"

    if [ -f "${ROOT_DIR}/Packaging/AppIcon.icns" ]; then
        cp "${ROOT_DIR}/Packaging/AppIcon.icns" "${W_DIR}/Contents/Resources/AppIcon.icns"
    fi

    # 4. Ad-Hoc Code Signing for extension
    echo "🔏 Code-signing widget extension at ${W_DIR}..."
    codesign --force --sign - --entitlements "${ROOT_DIR}/Packaging/KaruWidgets.entitlements" "${W_DIR}"
done

echo "🔏 Code-signing application bundle..."
codesign --force --deep --sign - "${APP_BUNDLE}"

# 5. Verify Code Signing
echo "🔍 Verifying code signature..."
codesign --verify --deep --strict --verbose=2 "${APP_BUNDLE}"

# 6. Create Distributable Archive (.zip)
ZIP_TARGET="${ROOT_DIR}/build/dist/Karu-v1.0.0-macOS.zip"
echo "🗜️ Creating distributable ZIP archive: ${ZIP_TARGET}..."
rm -f "${ZIP_TARGET}"
ditto -c -k --sequesterRsrc --keepParent "${APP_BUNDLE}" "${ZIP_TARGET}"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Standalone Karu.app packaged successfully!"
echo "📍 App Bundle: ${APP_BUNDLE}"
echo "📍 Dist ZIP:   ${ZIP_TARGET}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
