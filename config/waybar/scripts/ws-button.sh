#!/usr/bin/env bash
# Waybar custom module: shows a single workspace column button for the current project row
COL=$1
STATE_FILE="$HOME/.config/hyprcomp/state"

[[ -f "$STATE_FILE" ]] && source "$STATE_FILE" || current_row=0

ws=$((current_row * 10 + COL))
active_ws=$(hyprctl activeworkspace -j | jq -r '.id')
has_windows=$(hyprctl clients -j | jq --argjson ws "$ws" '[.[] | select(.workspace.id == $ws)] | length')

if [[ "$ws" -eq "$active_ws" ]]; then
    echo "{\"text\": \"$COL\", \"class\": \"active\"}"
elif [[ "$has_windows" -gt 0 ]]; then
    echo "{\"text\": \"$COL\", \"class\": \"occupied\"}"
else
    echo "{\"text\": \"\", \"class\": \"empty-ws\"}"
fi
