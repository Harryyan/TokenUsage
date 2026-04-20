#!/bin/bash
set -euo pipefail

# --------------------------------------------------
# build.sh — Build TokenUsage.app macOS menu-bar app
# --------------------------------------------------

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="TokenUsage"
BUNDLE_ID="com.tokenusage.app"
APP_BUNDLE="${PROJECT_DIR}/${APP_NAME}.app"
CONTENTS_DIR="${APP_BUNDLE}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"
ENTITLEMENTS="${PROJECT_DIR}/${APP_NAME}.entitlements"

# Detect architecture
ARCH="$(uname -m)"

echo "==> Building ${APP_NAME} (release)..."
cd "${PROJECT_DIR}"
swift build -c release 2>&1

# Locate the built binary.
# swift build puts it under .build/release/ or .build/<arch>-apple-macosx/release/
BINARY=""
if [ -f "${PROJECT_DIR}/.build/release/${APP_NAME}" ]; then
    BINARY="${PROJECT_DIR}/.build/release/${APP_NAME}"
elif [ -f "${PROJECT_DIR}/.build/${ARCH}-apple-macosx/release/${APP_NAME}" ]; then
    BINARY="${PROJECT_DIR}/.build/${ARCH}-apple-macosx/release/${APP_NAME}"
else
    echo "ERROR: Could not find built binary. Searching..."
    BINARY="$(find "${PROJECT_DIR}/.build" -name "${APP_NAME}" -type f -perm +111 | grep release | head -1)"
    if [ -z "${BINARY}" ]; then
        echo "ERROR: Build succeeded but binary not found."
        exit 1
    fi
fi
echo "==> Binary found at: ${BINARY}"

# Clean previous bundle
if [ -d "${APP_BUNDLE}" ]; then
    echo "==> Removing previous ${APP_NAME}.app..."
    rm -rf "${APP_BUNDLE}"
fi

# Create .app bundle structure
echo "==> Creating app bundle..."
mkdir -p "${MACOS_DIR}"
mkdir -p "${RESOURCES_DIR}"

# Copy binary
cp "${BINARY}" "${MACOS_DIR}/${APP_NAME}"
chmod +x "${MACOS_DIR}/${APP_NAME}"

# Get the short version from git tag or default
VERSION="1.0.0"
BUILD_NUMBER="1"

# Generate full Info.plist for the bundle
cat > "${CONTENTS_DIR}/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleDevelopmentRegion</key>
	<string>en</string>
	<key>CFBundleExecutable</key>
	<string>${APP_NAME}</string>
	<key>CFBundleIdentifier</key>
	<string>${BUNDLE_ID}</string>
	<key>CFBundleInfoDictionaryVersion</key>
	<string>6.0</string>
	<key>CFBundleName</key>
	<string>${APP_NAME}</string>
	<key>CFBundleDisplayName</key>
	<string>Token Usage</string>
	<key>CFBundlePackageType</key>
	<string>APPL</string>
	<key>CFBundleShortVersionString</key>
	<string>${VERSION}</string>
	<key>CFBundleVersion</key>
	<string>${BUILD_NUMBER}</string>
	<key>LSMinimumSystemVersion</key>
	<string>13.0</string>
	<key>LSUIElement</key>
	<true/>
	<key>CFBundleIconFile</key>
	<string>AppIcon</string>
	<key>NSHighResolutionCapable</key>
	<true/>
	<key>NSSupportsAutomaticTermination</key>
	<true/>
	<key>NSSupportsSuddenTermination</key>
	<true/>
</dict>
</plist>
PLIST

# Copy entitlements into Resources (for reference)
if [ -f "${ENTITLEMENTS}" ]; then
    cp "${ENTITLEMENTS}" "${RESOURCES_DIR}/${APP_NAME}.entitlements"
fi

# Copy app icon
ICON_FILE="${PROJECT_DIR}/AppIcon.icns"
if [ -f "${ICON_FILE}" ]; then
    cp "${ICON_FILE}" "${RESOURCES_DIR}/AppIcon.icns"
    echo "==> App icon copied."
fi

# Ad-hoc code sign with entitlements
echo "==> Signing ${APP_NAME}.app (ad-hoc)..."
if [ -f "${ENTITLEMENTS}" ]; then
    codesign --force --sign - --entitlements "${ENTITLEMENTS}" --deep "${APP_BUNDLE}"
else
    codesign --force --sign - --deep "${APP_BUNDLE}"
fi

echo ""
echo "==> Build complete!"
echo "    ${APP_BUNDLE}"
echo ""
echo "    To run:  open \"${APP_BUNDLE}\""
echo "    To install: cp -R \"${APP_BUNDLE}\" /Applications/"
