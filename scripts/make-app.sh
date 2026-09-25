#!/bin/sh
# Builds dist/Hopla.app (menu bar app, no Dock icon).
set -eu
cd "$(dirname "$0")/.."

# ./scripts/make-app.sh --universal  → one binary for Apple Silicon and Intel Macs.
swift build -c release
BIN="$(swift build -c release --show-bin-path)/Hopla"
APP="dist/Hopla.app"
VERSION="$(cat VERSION)"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
if [ "${1:-}" = "--universal" ]; then
    swift build -c release --triple x86_64-apple-macosx13.0
    INTEL="$(swift build -c release --triple x86_64-apple-macosx13.0 --show-bin-path)/Hopla"
    lipo -create "$BIN" "$INTEL" -output "$APP/Contents/MacOS/Hopla"
else
    cp "$BIN" "$APP/Contents/MacOS/Hopla"
fi

# App icon, drawn by Hopla itself.
"$BIN" --icon dist/icon/AppIcon.iconset >/dev/null
iconutil -c icns dist/icon/AppIcon.iconset -o "$APP/Contents/Resources/AppIcon.icns"

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key><string>Hopla</string>
    <key>CFBundleDisplayName</key><string>Hopla</string>
    <key>CFBundleIdentifier</key><string>io.github.justinsimontospace.hopla</string>
    <key>CFBundleExecutable</key><string>Hopla</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleIconFile</key><string>AppIcon</string>
    <key>CFBundleShortVersionString</key><string>$VERSION</string>
    <key>CFBundleVersion</key><string>1</string>
    <key>LSMinimumSystemVersion</key><string>13.0</string>
    <key>LSUIElement</key><true/>
    <key>NSHighResolutionCapable</key><true/>
    <key>NSHumanReadableCopyright</key><string>© 2026 Justin Simon — PolyForm Noncommercial 1.0.0</string>
</dict>
</plist>
PLIST

# Ad-hoc signature so macOS lets it run locally.
codesign --force --sign - "$APP" >/dev/null 2>&1 || true
echo "→ $APP"
