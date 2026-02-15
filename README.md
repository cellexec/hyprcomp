# HyprComp

2D project-based workspace grid for Hyprland.

Organizes workspaces into a grid where rows are projects and columns are windows within a project. Navigate horizontally between windows and vertically between projects with gestures, keybindings, and a waybar integration that shows only the current project's workspaces.

```
                 Column 1      Column 2      Column 3
Project A:       ws 1          ws 2          ws 3
Project B:       ws 11         ws 12         ws 13
Project C:       ws 21         ws 22         ws 23
```

## Features

- **3-finger horizontal swipe** - switch between windows in current project (row-bounded)
- **3-finger vertical swipe** - switch between projects (preserves column position)
- **SUPER+1-9** - project-relative workspace switching (column N of current row)
- **SUPER+CTRL+UP/DOWN** - switch projects via keyboard
- **SUPER+SHIFT+1-9** - move window to column N of current row
- **Directional animations** - horizontal slide for column switches, vertical slide for project switches
- **Waybar integration** - project name + row-aware workspace buttons with click support
- **Workspace overview** - fullscreen overlay showing all projects and workspaces in a 2D grid (SUPER+Tab), with cached workspace screenshots, keyboard shortcuts, and live gesture tracking
- **Project launcher** - create new projects from ~/projects folders; auto-launches claude code, chromium (isolated profile), and nvim
- **Auto-reorder** - deleting a project compacts row IDs and moves windows so new projects always append at the end
- **Persistent state** - project names survive reboots

## Dependencies

- Hyprland
- jq
- waybar (optional, for bar integration)
- Python 3.11+ with PyGObject, gtk4-layer-shell (optional, for workspace overview)
- grim (optional, for workspace screenshots in overview)

## Installation

### 1. Clone the repo

```bash
git clone https://github.com/your-user/hyprcomp ~/projects/hyprcomp
chmod +x ~/projects/hyprcomp/hyprcomp
```

### 2. Hyprland keybindings

Copy the keybinding config and source it from your `hyprland.conf`:

```bash
cp ~/projects/hyprcomp/config/hypr/hyprcomp.conf ~/.config/hypr/hyprcomp.conf
```

Add this line at the **end** of `~/.config/hypr/hyprland.conf` (the config unbinds default SUPER+1-9 workspace switching and replaces it with project-relative navigation):

```conf
source = ~/.config/hypr/hyprcomp.conf
```

### 3. Gesture bindings

In your `~/.config/hypr/input.conf`, **remove** the default horizontal workspace gesture:

```conf
# Remove this line:
gesture = 3, horizontal, workspace
```

**Replace** it with the hyprcomp gestures (or source the provided config):

```conf
# 3-finger horizontal: switch columns within project row
gesture = 3, l, dispatcher, exec, ~/projects/hyprcomp/hyprcomp right
gesture = 3, r, dispatcher, exec, ~/projects/hyprcomp/hyprcomp left

# 3-finger vertical: switch between projects
gesture = 3, u, dispatcher, exec, ~/projects/hyprcomp/hyprcomp down
gesture = 3, d, dispatcher, exec, ~/projects/hyprcomp/hyprcomp up
```

### 4. Waybar integration (optional)

Copy the scripts:

```bash
cp ~/projects/hyprcomp/config/waybar/scripts/project.sh ~/.config/waybar/scripts/
cp ~/projects/hyprcomp/config/waybar/scripts/ws-button.sh ~/.config/waybar/scripts/
```

In your waybar `config.jsonc`, replace `"hyprland/workspaces"` in `modules-left` with:

```json
"modules-left": ["custom/project", "custom/ws-1", "custom/ws-2", "custom/ws-3", "custom/ws-4", "custom/ws-5", "custom/ws-6", "custom/ws-7", "custom/ws-8", "custom/ws-9"],
```

Then merge the module definitions from `config/waybar/hyprcomp-modules.jsonc` into your config.

Add the styles from `config/waybar/hyprcomp.css` to your waybar `style.css`. The CSS uses Catppuccin Mocha color variables -- adjust to match your theme.

### 5. Autostart the overview daemon (optional)

The workspace overview runs as a persistent daemon for instant SUPER+Tab. Add to your Hyprland autostart:

```conf
exec-once = ~/projects/hyprcomp/hyprcomp-overview &
```

Without autostart, the first SUPER+Tab has a ~1s cold start (Python imports), then subsequent toggles are instant.

### 6. Reload

```bash
hyprctl reload
killall waybar; waybar &disown
```

## Usage

### Create projects

From the overview (SUPER+Tab), click "+ New Project" to pick a folder from `~/projects/`. Selecting a folder creates the project and launches windows based on its config (see below). Folders with subprojects show a `›` suffix and expand into a sub-picker.

Or from the command line:

```bash
hyprcomp create homelab        # Row 0, workspaces 1-10
hyprcomp create guitar-studio  # Row 1, workspaces 11-20
hyprcomp create homelab/flux   # Subproject — resolves to ~/projects/homelab/flux
```

### Per-project configuration

Place a `.hyprcomp.toml` in any project root to control which windows launch:

```toml
[[windows]]
exec = "claude"
terminal = true     # Wrap in alacritty terminal

[[windows]]
exec = "chromium"
browser = true      # Add --user-data-dir for isolation

[[windows]]
exec = "nvim"
terminal = true
# cwd = "subdir"    # Optional: working dir relative to project root
```

Window types:
- `terminal = true` — runs in alacritty with zsh
- `browser = true` — adds `--user-data-dir` for per-project isolation
- `url_env = "VAR"` — reads `VAR` from the project's `.env` file and opens it in the browser
- Neither — launched as a plain GUI app via hyprctl

### Subprojects (monorepo support)

Directories with `[[subprojects]]` in their `.hyprcomp.toml` expand into separate projects in the picker:

```toml
[[subprojects]]
path = "flux"

[[subprojects]]
path = "monorepo/apps/web"
name = "monorepo-web"       # Optional display name
```

Subprojects can nest — if a subproject directory itself contains a `.hyprcomp.toml` with `[[subprojects]]`, it expands further (e.g., `homelab ›` → `monorepo ›` → individual apps).

Subproject names are stored as `parent/path` (e.g., `homelab/flux`) and resolve to the full filesystem path.

### Config resolution

1. `<project_dir>/.hyprcomp.toml` `[[windows]]`
2. `~/.config/hyprcomp/defaults.toml` `[[windows]]` (global defaults)
3. Built-in defaults (claude, chromium, nvim)

### Navigate

| Action | Gesture | Keybinding |
|--------|---------|------------|
| Next window (right) | 3-finger swipe left | SUPER+2, SUPER+3, ... |
| Previous window (left) | 3-finger swipe right | SUPER+1 |
| Next project (down) | 3-finger swipe up | SUPER+CTRL+DOWN |
| Previous project (up) | 3-finger swipe down | SUPER+CTRL+UP |
| Move window to column N | | SUPER+SHIFT+N |
| Jump to column N | | SUPER+N |
| Workspace overview | | SUPER+Tab |

### Overview keyboard shortcuts

| Key | Action |
|-----|--------|
| Click cell | Switch to that workspace |
| d | Close all windows in hovered workspace |
| a | Open new workspace at end of hovered project |
| x | Delete hovered project (closes all windows) |
| q / Escape | Close overlay |

### Manage projects

```bash
hyprcomp list              # Show all projects (* marks current)
hyprcomp status            # Current workspace, row, and column
hyprcomp rename new-name   # Rename current project
hyprcomp delete            # Remove current project registration
hyprcomp overview          # Toggle workspace overview overlay
hyprcomp restart           # Restart the overview daemon
```

## How it works

Each project gets a row of 10 workspace slots. Row 0 uses workspaces 1-10, row 1 uses 11-20, and so on (up to 9 rows).

The `hyprcomp` script translates all navigation into absolute workspace numbers and dispatches via `hyprctl`. Before each dispatch, it sets the animation direction dynamically -- `slide` for horizontal movement, `slidevert` for vertical -- so transitions feel natural. A screenshot of the current workspace is cached on each switch for the overview thumbnails.

The overview overlay (`hyprcomp-overview`) is a GTK4 + layer-shell Python app that runs as a persistent daemon. It queries Hyprland's IPC socket directly (~2.5ms for all data) and listens on socket2 for live workspace change events. Screenshots are captured asynchronously via grim.

State is stored in `~/.config/hyprcomp/`:
- `state` - current row number
- `projects` - row-to-name mapping (e.g., `0:homelab`)
- `defaults.toml` - global default windows config (optional)
- `chromium/<name>/` - isolated Chromium profiles per project

Per-project config lives in `<project_dir>/.hyprcomp.toml`.

Workspace thumbnails are cached in `~/.cache/hyprcomp/thumbs/`.

The waybar modules replace the built-in `hyprland/workspaces` widget with custom scripts that only show workspaces belonging to the current project row, labeled with column numbers (1-9) instead of absolute workspace IDs.

## Uninstalling

1. Remove `source = ~/.config/hypr/hyprcomp.conf` from `hyprland.conf`
2. Restore `gesture = 3, horizontal, workspace` in `input.conf`
3. Restore `"hyprland/workspaces"` in your waybar config
4. `hyprctl reload && killall waybar && waybar &disown`
5. Remove `~/.config/hyprcomp/` and `~/.config/hypr/hyprcomp.conf`
