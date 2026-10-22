#!/bin/zsh
# Builds Halo.app and installs it into /Applications.
set -e
DIR="${0:A:h}"
APP="$DIR/build/Halo.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

swiftc -O -swift-version 5 -parse-as-library -target arm64-apple-macos15 \
  "$DIR"/App/*.swift -o "$APP/Contents/MacOS/Halo"

ICONSET="$DIR/build/AppIcon.iconset"
swift "$DIR/tools/makeicon.swift" "$ICONSET"
iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/AppIcon.icns"

cat > "$APP/Contents/Info.plist" <<PL
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleName</key><string>Halo</string>
  <key>CFBundleDisplayName</key><string>Halo</string>
  <key>CFBundleIdentifier</key><string>local.halo.Halo</string>
  <key>CFBundleExecutable</key><string>Halo</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleIconFile</key><string>AppIcon</string>
  <key>CFBundleShortVersionString</key><string>1.0</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>LSMinimumSystemVersion</key><string>15.0</string>
  <key>LSUIElement</key><true/>
  <key>NSHumanReadableCopyright</key><string>Halo — a driver for the Logitech NuLOOQ Navigator</string>
</dict></plist>
PL

codesign --force --sign - "$APP"

rm -rf "/Applications/Halo.app"
cp -R "$APP" /Applications/
echo "Installed /Applications/Halo.app"
