#!/bin/zsh
launchctl bootout "gui/$UID/net.local.nulooqd" 2>/dev/null
rm -f "$HOME/Library/LaunchAgents/net.local.nulooqd.plist"
echo "Uninstalled."
