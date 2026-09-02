#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🚀 Karu Focus Timer — System Installer & Widget Registar"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 1. Build and package Karu.app + KaruWidgets.appex
echo "📦 Building and packaging Karu.app with embedded widgets..."
"${ROOT_DIR}/scripts/build_app.sh"

APP_SOURCE="${ROOT_DIR}/build/Karu.app"
APP_DEST="/Applications/Karu.app"

if [ ! -d "${APP_SOURCE}" ]; then
    echo "❌ Error: Build output not found at ${APP_SOURCE}"
    exit 1
fi

# 2. Install to /Applications/
echo "📂 Installing Karu to ${APP_DEST}..."
rm -rf "${APP_DEST}"
cp -R "${APP_SOURCE}" "${APP_DEST}"

# 3. Register with macOS LaunchServices & WidgetKit
echo "🔄 Registering application & widget extension with macOS LaunchServices..."
LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"

if [ -f "${LSREGISTER}" ]; then
    "${LSREGISTER}" -f -R -trusted "${APP_DEST}"
fi

if [ -d "${APP_DEST}/Contents/Extensions/KaruWidgets.appex" ]; then
    pluginkit -a "${APP_DEST}/Contents/Extensions/KaruWidgets.appex" 2>/dev/null || true
    pluginkit -e use -i com.karu.focustimer.widgets 2>/dev/null || true
fi

# 4. Flush widget daemon cache so macOS desktop discovers new widgets immediately
echo "✨ Refreshing macOS WidgetKit cache..."
killall widgetkitd 2>/dev/null || true
killall NotificationCenter 2>/dev/null || true

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎉 Installation Complete! Karu is now in /Applications/"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📱 How to add Karu Widgets to your macOS Desktop:"
echo " 1. Right-click anywhere on your Desktop wallpaper."
echo " 2. Select 'Edit Widgets...' from the context menu."
echo " 3. Search for 'Karu' in the widget gallery on the left."
echo " 4. Drag either:"
echo "    • 🎯 Airspeed & Quota Gauge (Small — 540 kts, progress ring, streak)"
echo "    • 📋 Focus Flight Dispatch (Medium — Route, ETA, 1-Click Takeoff)"
echo "    directly onto your desktop!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
