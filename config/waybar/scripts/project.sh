#!/usr/bin/env bash
# Outputs current hyprcomp project name for waybar

CONFIG_DIR="$HOME/.config/hyprcomp"
STATE_FILE="$CONFIG_DIR/state"
PROJECTS_FILE="$CONFIG_DIR/projects"

get_active_workspace() {
    hyprctl activeworkspace -j | jq -r '.id'
}

workspace_to_row() {
    echo $(( ($1 - 1) / 10 ))
}

get_project_name() {
    local row=$1
    if [[ -f "$PROJECTS_FILE" ]]; then
        grep "^${row}:" "$PROJECTS_FILE" 2>/dev/null | cut -d: -f2- || echo ""
    fi
}

DESKTOP_ROW=9

ws=$(get_active_workspace)
row=$(workspace_to_row "$ws")
name=$(get_project_name "$row")

if [[ $row -eq $DESKTOP_ROW ]]; then
    echo "{\"text\": \"Desktop\", \"tooltip\": \"Desktop (row $row)\", \"class\": \"active\"}"
elif [[ -n "$name" ]]; then
    display="${name##*/}"
    # Calculate project index (1-based) and total
    total=$(wc -l < "$PROJECTS_FILE" 2>/dev/null || echo 0)
    idx=1
    while IFS=: read -r r _; do
        [[ $r -eq $row ]] && break
        idx=$((idx + 1))
    done < "$PROJECTS_FILE"
    echo "{\"text\": \"$idx/$total | $display\", \"tooltip\": \"Project: $name (row $row)\", \"class\": \"active\"}"
else
    echo "{\"text\": \"\", \"tooltip\": \"\", \"class\": \"empty\"}"
fi
