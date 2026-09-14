#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

TARGET_FILE="${1:-${ROOT_DIR}/build/dist/Karu-v1.0.0.dmg}"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔏 Karu Focus Timer — Apple Notarization Helper"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ ! -f "${TARGET_FILE}" ]; then
    echo "❌ Error: Target file not found: ${TARGET_FILE}"
    echo "Usage: $0 [path/to/file.dmg|path/to/file.zip]"
    exit 1
fi

echo "📦 Target Artifact: ${TARGET_FILE}"

# 1. Determine Notarization Authentication Method
if [ -n "${KEYCHAIN_PROFILE}" ]; then
    echo "🔑 Using Keychain Profile: ${KEYCHAIN_PROFILE}"
    AUTH_ARGS=(--keychain-profile "${KEYCHAIN_PROFILE}")
elif [ -n "${APPLE_ID}" ] && [ -n "${APPLE_APP_SPECIFIC_PASSWORD}" ] && [ -n "${APPLE_TEAM_ID}" ]; then
    echo "🔑 Using Apple ID: ${APPLE_ID} (Team: ${APPLE_TEAM_ID})"
    AUTH_ARGS=(--apple-id "${APPLE_ID}" --password "${APPLE_APP_SPECIFIC_PASSWORD}" --team-id "${APPLE_TEAM_ID}")
else
    echo "⚠️  Missing Notarization Credentials!"
    echo ""
    echo "Please set one of the following:"
    echo "  Method A (Keychain profile created via 'xcrun notarytool store-credentials'):"
    echo "    export KEYCHAIN_PROFILE=\"AC_PASSWORD\""
    echo ""
    echo "  Method B (Environment variables):"
    echo "    export APPLE_ID=\"your-apple-id@example.com\""
    echo "    export APPLE_APP_SPECIFIC_PASSWORD=\"abcd-efgh-ijkl-mnop\""
    echo "    export APPLE_TEAM_ID=\"XXXXXXXXXX\""
    echo ""
    exit 1
fi

# 2. Submit to Apple Notary Service
echo "🚀 Submitting to Apple Notary Service (waiting for response)..."
xcrun notarytool submit "${TARGET_FILE}" "${AUTH_ARGS[@]}" --wait

# 3. Staple Ticket (if DMG)
if [[ "${TARGET_FILE}" == *.dmg ]]; then
    echo "📎 Stapling notarization ticket to DMG..."
    xcrun stapler staple "${TARGET_FILE}"
    echo "🔍 Validating stapled ticket..."
    xcrun stapler validate "${TARGET_FILE}"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Notarization & Stapling Succeeded!"
echo "📍 Artifact: ${TARGET_FILE}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
