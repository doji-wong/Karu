#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "💿 Karu Focus Timer — Standalone DMG Packager"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 1. Build and assemble app bundle if not already present
APP_BUNDLE="${ROOT_DIR}/build/Karu.app"
if [ ! -d "${APP_BUNDLE}" ]; then
    echo "📦 Application bundle not found. Building Karu.app first..."
    "${ROOT_DIR}/scripts/build_app.sh"
fi

# 2. Setup Staging Directory
DIST_DIR="${ROOT_DIR}/build/dist"
STAGING_DIR="${ROOT_DIR}/build/dmg_staging"
TMP_DMG="${ROOT_DIR}/build/Karu_temp.dmg"
FINAL_DMG="${DIST_DIR}/Karu-v1.0.0.dmg"

mkdir -p "${DIST_DIR}"
rm -rf "${STAGING_DIR}" "${TMP_DMG}" "${FINAL_DMG}"
mkdir -p "${STAGING_DIR}"

echo "📂 Staging files for disk image..."
cp -R "${APP_BUNDLE}" "${STAGING_DIR}/Karu.app"
ln -s /Applications "${STAGING_DIR}/Applications"

# Copy Volume Icon if available
if [ -f "${ROOT_DIR}/Packaging/AppIcon.icns" ]; then
    cp "${ROOT_DIR}/Packaging/AppIcon.icns" "${STAGING_DIR}/.VolumeIcon.icns"
fi

# 3. Create temporary read-write DMG
VOLUME_NAME="Karu Focus Timer"
echo "📦 Creating temporary DMG (${VOLUME_NAME})..."
hdiutil create -ov -srcfolder "${STAGING_DIR}" -volname "${VOLUME_NAME}" -fs HFS+ -fsargs "-c c=64,a=16,e=16" -format UDRW "${TMP_DMG}"

# 4. Mount disk image for Finder styling
echo "🖥️  Mounting temporary DMG for Finder layout styling..."
MOUNT_POINT="/Volumes/${VOLUME_NAME}"

# Ensure not already mounted
if [ -d "${MOUNT_POINT}" ]; then
    hdiutil detach "${MOUNT_POINT}" -force 2>/dev/null || true
fi

hdiutil attach -readwrite -noverify -noautoopen "${TMP_DMG}"

# Enable Volume Icon attribute if SetFile is available
if command -v SetFile &> /dev/null && [ -f "${MOUNT_POINT}/.VolumeIcon.icns" ]; then
    SetFile -a C "${MOUNT_POINT}" 2>/dev/null || true
    SetFile -a V "${MOUNT_POINT}/.VolumeIcon.icns" 2>/dev/null || true
fi

# 5. Apply AppleScript Finder layout styling
echo "🎨 Applying Finder window layout (540x380, centered icons)..."
osascript <<APPLESCRIPT || true
tell application "Finder"
    tell disk "${VOLUME_NAME}"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {400, 200, 940, 580}
        set viewOptions to the icon view options of container window
        set arrangement of viewOptions to not arranged
        set icon size of viewOptions to 110
        set position of item "Karu.app" of container window to {130, 180}
        set position of item "Applications" of container window to {410, 180}
        update without registering applications
        delay 1
        close
    end tell
end tell
APPLESCRIPT

# Clean up Finder cache and hidden trash
rm -rf "${MOUNT_POINT}/.Trashes" "${MOUNT_POINT}/.fseventsd" 2>/dev/null || true
sync

# 6. Unmount temporary DMG
echo "🔒 Unmounting temporary DMG..."
hdiutil detach "${MOUNT_POINT}" -force

# 7. Convert to compressed read-only UDZO image
echo "🗜️ Compressing final release DMG..."
hdiutil convert "${TMP_DMG}" -format UDZO -imagekey zlib-level=9 -o "${FINAL_DMG}"

# Clean up temporary files
rm -rf "${TMP_DMG}" "${STAGING_DIR}"

# 8. Sign DMG if CODESIGN_IDENTITY is configured
CODESIGN_IDENTITY="${CODESIGN_IDENTITY:--}"
if [ "${CODESIGN_IDENTITY}" != "-" ]; then
    echo "🔏 Signing DMG with ${CODESIGN_IDENTITY}..."
    codesign --force --timestamp --sign "${CODESIGN_IDENTITY}" "${FINAL_DMG}"
    echo "🔍 Verifying DMG signature..."
    codesign --verify --verbose=2 "${FINAL_DMG}"
fi

# 9. Compute Checksum
CHECKSUM=$(shasum -a 256 "${FINAL_DMG}" | awk '{print $1}')
FILE_SIZE=$(ls -lh "${FINAL_DMG}" | awk '{print $5}')

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎉 Standalone DMG Packaged Successfully!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📍 Location: ${FINAL_DMG}"
echo "📏 Size:     ${FILE_SIZE}"
echo "🔑 SHA256:   ${CHECKSUM}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
