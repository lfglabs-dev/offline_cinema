#!/bin/bash

# Build script for OfflineCinema.app

set -e

APP_NAME="OfflineCinema"
BUILD_DIR=".build/release"
APP_BUNDLE="$APP_NAME.app"
CONTENTS_DIR="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo "🎬 Building $APP_NAME in release mode..."
swift build -c release

echo "📦 Creating app bundle..."

# Remove old bundle if exists
rm -rf "$APP_BUNDLE"

# Create directory structure
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# Copy executable
cp "$BUILD_DIR/$APP_NAME" "$MACOS_DIR/"

# Copy app icon
echo "🎨 Copying app icon..."
if [ -f "branding/AppIcon.icns" ]; then
    cp "branding/AppIcon.icns" "$RESOURCES_DIR/"
else
    echo "⚠️  No AppIcon.icns found. Run 'python3 generate-icons.py' to generate icons."
fi

# Create Info.plist
cat > "$CONTENTS_DIR/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.offlinecinema.app</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>Offline Cinema</string>
    <key>CFBundleDisplayName</key>
    <string>Offline Cinema</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSSupportsAutomaticGraphicsSwitching</key>
    <true/>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.video</string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>CFBundleDocumentTypes</key>
    <array>
        <dict>
            <key>CFBundleTypeName</key>
            <string>Video</string>
            <key>CFBundleTypeRole</key>
            <string>Viewer</string>
            <key>LSHandlerRank</key>
            <string>Alternate</string>
            <key>LSItemContentTypes</key>
            <array>
                <string>public.movie</string>
                <string>public.mpeg-4</string>
                <string>com.apple.quicktime-movie</string>
                <string>public.avi</string>
                <string>org.matroska.mkv</string>
            </array>
        </dict>
    </array>
    <key>UTImportedTypeDeclarations</key>
    <array>
        <dict>
            <key>UTTypeIdentifier</key>
            <string>org.matroska.mkv</string>
            <key>UTTypeDescription</key>
            <string>Matroska Video</string>
            <key>UTTypeConformsTo</key>
            <array>
                <string>public.movie</string>
            </array>
            <key>UTTypeTagSpecification</key>
            <dict>
                <key>public.filename-extension</key>
                <array>
                    <string>mkv</string>
                </array>
            </dict>
        </dict>
    </array>
</dict>
</plist>
EOF

# Create PkgInfo
echo -n "APPL????" > "$CONTENTS_DIR/PkgInfo"

echo "✅ App bundle created: $APP_BUNDLE"
echo ""
echo "🚀 Launching Offline Cinema..."

# Quit any running instance so UI changes always apply
osascript -e 'tell application "OfflineCinema" to quit' >/dev/null 2>&1 || true
osascript -e 'tell application "Offline Cinema" to quit' >/dev/null 2>&1 || true
pkill -x OfflineCinema >/dev/null 2>&1 || true
sleep 0.5

open "$APP_BUNDLE"

