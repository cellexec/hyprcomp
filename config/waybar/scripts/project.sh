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

ws=$(get_active_workspace)
row=$(workspace_to_row "$ws")
name=$(get_project_name "$row")

if [[ -n "$name" ]]; then
    echo "{\"text\": \"$name\", \"tooltip\": \"Project: $name (row $row)\", \"class\": \"active\"}"
else
    echo "{\"text\": \"\", \"tooltip\": \"\", \"class\": \"empty\"}"
fi
