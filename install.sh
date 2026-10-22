#!/bin/zsh
# Builds nulooqd and installs it as a LaunchAgent so it runs at login.
set -e
DIR="${0:A:h}"
LABEL=net.local.nulooqd
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"

swiftc -O "$DIR/nulooqd.swift" -o "$DIR/nulooqd"

cat > "$PLIST" <<PL
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>$LABEL</string>
  <key>ProgramArguments</key><array><string>$DIR/nulooqd</string></array>
  <key>RunAtLoad</key><true/>
  <key>KeepAlive</key><true/>
  <key>StandardErrorPath</key><string>$HOME/Library/Logs/nulooqd.log</string>
</dict></plist>
PL

launchctl bootout "gui/$UID/$LABEL" 2>/dev/null || true
launchctl bootstrap "gui/$UID" "$PLIST"
echo "Installed. Log: ~/Library/Logs/nulooqd.log"
echo "Grant Accessibility to $DIR/nulooqd in System Settings > Privacy & Security > Accessibility,"
echo "then run:  launchctl kickstart -k gui/$UID/$LABEL"
