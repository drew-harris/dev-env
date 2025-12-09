#!/bin/bash
# toggle_pip.sh

HIDDEN_WS="Z"  # or any workspace you don't use

# Find Helium PiP window
WIN_ID=$(/opt/homebrew/bin/aerospace list-windows --all | grep "Picture in Picture" | head -1 | awk '{print $1}')

if [ -z "$WIN_ID" ]; then
    exit 0
fi

# Get current workspace of the window
CURRENT_WS=$(/opt/homebrew/bin/aerospace list-windows --all --format '%{window-id} %{workspace}' | grep "^$WIN_ID " | awk '{print $2}')

if [ "$CURRENT_WS" = "$HIDDEN_WS" ]; then
    # Bring it back to focused workspace
    /opt/homebrew/bin/aerospace move-node-to-workspace --window-id "$WIN_ID" $(/opt/homebrew/bin/aerospace list-workspaces --focused)
else
    # Hide it
    /opt/homebrew/bin/aerospace move-node-to-workspace --window-id "$WIN_ID" "$HIDDEN_WS"
fi
