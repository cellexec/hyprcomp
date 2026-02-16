# HyprComp

2D project-based workspace grid for Hyprland. Each project gets its own row of workspaces, so you can swipe between projects vertically and between windows horizontally.

> [!WARNING]
> This was built on a live [Omarchy](https://omarchy.com) instance and has never been tested as a fresh install on a clean Arch/Hyprland setup. The installation guide below is a best-effort reference, not a guaranteed step-by-step. Paths, dependencies, and config formats may vary depending on your setup. PRs to improve portability are welcome.

<!-- TODO: Add hero screenshot/gif of the overview here -->
<!-- ![HyprComp Overview](assets/overview.png) -->

## How it works

Workspaces are organized into a 2D grid. Rows are projects, columns are windows within a project. A dedicated Desktop row at the top holds standalone apps that persist across project changes.

```
                 Column 1      Column 2      Column 3
Desktop:         ws 91         ws 92         ws 93        (row 9, always present)
Project A:       ws 1          ws 2          ws 3         (row 0)
Project B:       ws 11         ws 12         ws 13        (row 1)
Project C:       ws 21         ws 22         ws 23        (row 2)
```

The `hyprcomp` script translates navigation into absolute workspace numbers and dispatches via `hyprctl`, with directional animations (horizontal slide, vertical slide, fade for Desktop). The overview is a GTK4 + layer-shell daemon that queries Hyprland's IPC socket directly (~2.5ms) and captures workspace screenshots via grim.

## Features

### Workspace overview

Fullscreen overlay showing all projects in a 2D grid with live workspace thumbnails, active badge, and keyboard navigation.

<!-- TODO: Add gif/video of overview toggle -->
<!-- ![Overview](assets/overview.gif) -->

### Gesture navigation

3-finger swipe horizontally between windows, vertically between projects. Swiping down past the last project opens the project launcher.

<!-- TODO: Add gif of gesture navigation -->
<!-- ![Gestures](assets/gestures.gif) -->

### Desktop row

Dedicated row for standalone apps (browser, Discord, etc.) that persists when closing all projects. Always shown at the top of the overview.

<!-- TODO: Add screenshot showing Desktop row in overview -->
<!-- ![Desktop Row](assets/desktop-row.png) -->

### Project launcher

Pick a folder from `~/projects/` via walker menu (SUPER+N). Supports nested subprojects for monorepos. Automatically launches configured apps per `.hyprcomp.toml`.

<!-- TODO: Add gif of project launcher -->
<!-- ![Project Launcher](assets/launcher.gif) -->

### Quick close (SUPER+X)

Close the current project with a confirm dialog without opening the overview. Instant response via the running daemon.

<!-- TODO: Add gif of quick close -->
<!-- ![Quick Close](assets/quick-close.gif) -->

### Waybar integration

Project name with index (`1/4 | myproject`) and row-aware workspace buttons that only show the current project's workspaces.

<!-- TODO: Add screenshot of waybar -->
<!-- ![Waybar](assets/waybar.png) -->

### Per-project app config

Each project can define which apps to launch in `.hyprcomp.toml`, with isolated Chromium profiles and environment-based URLs.

<!-- TODO: Add screenshot of terminal with .hyprcomp.toml -->
<!-- ![Config](assets/config.png) -->

## Keybindings

### Navigation

| Action | Gesture | Keybinding |
|--------|---------|------------|
| Next window | 3-finger swipe left | `SUPER+1-0` |
| Previous window | 3-finger swipe right | `SUPER+1-0` |
| Next project | 3-finger swipe up | `SUPER+CTRL+DOWN` |
| Previous project | 3-finger swipe down | `SUPER+CTRL+UP` |
| Move window to column | | `SUPER+SHIFT+1-0` |
| Workspace overview | | `SUPER+Tab` |
| Close current project | | `SUPER+X` |
| New project | | `SUPER+N` |
| Restart overview | | `SUPER+R` |

### Overview shortcuts

| Key | Action |
|-----|--------|
| `hjkl` / arrows | Navigate between workspaces |
| `Enter` | Switch to selected workspace |
| `0` / backtick | Jump to Desktop row |
| `1-9` | Jump to Nth project |
| `d` | Close all windows in hovered workspace |
| `a` | Open new workspace in hovered project |
| `n` | Open project launcher |
| `x` / `Delete` | Close hovered project (Desktop cannot be deleted) |
| `q` / `Escape` | Close overlay |

## Installation

### Dependencies

- [Hyprland](https://hyprland.org)
- jq
- [alacritty](https://alacritty.org) (terminal)
- [walker](https://github.com/abenz1267/walker) (project launcher menu)
- [waybar](https://github.com/Alexays/Waybar) (optional, bar integration)
- Python 3.11+ with PyGObject, gtk4-layer-shell (optional, overview)
- [grim](https://sr.ht/~emersion/grim/) (optional, workspace screenshots)

### Setup

```bash
git clone https://github.com/cellexec/hyprcomp ~/projects/hyprcomp
chmod +x ~/projects/hyprcomp/hyprcomp
```

**Hyprland config** -- source the keybinding config (this unbinds default SUPER+1-9 and replaces with project-relative navigation):

```bash
cp ~/projects/hyprcomp/config/hypr/hyprcomp.conf ~/.config/hypr/hyprcomp.conf
```

```conf
# Add to end of ~/.config/hypr/hyprland.conf
source = ~/.config/hypr/hyprcomp.conf
```

**Gesture bindings** -- replace the default horizontal workspace gesture:

```conf
# 3-finger horizontal: switch columns within project row
gesture = 3, l, dispatcher, exec, ~/projects/hyprcomp/hyprcomp right
gesture = 3, r, dispatcher, exec, ~/projects/hyprcomp/hyprcomp left

# 3-finger vertical: switch between projects
gesture = 3, u, dispatcher, exec, ~/projects/hyprcomp/hyprcomp down
gesture = 3, d, dispatcher, exec, ~/projects/hyprcomp/hyprcomp up
```

**Waybar** (optional):

```bash
cp ~/projects/hyprcomp/config/waybar/scripts/project.sh ~/.config/waybar/scripts/
cp ~/projects/hyprcomp/config/waybar/scripts/ws-button.sh ~/.config/waybar/scripts/
```

Replace `"hyprland/workspaces"` in your waybar config with the modules from `config/waybar/hyprcomp-modules.jsonc` and add styles from `config/waybar/hyprcomp.css`.

**Overview daemon** (optional) -- for instant SUPER+Tab:

```conf
# Add to Hyprland autostart
exec-once = ~/projects/hyprcomp/hyprcomp-overview &
```

**Reload:**

```bash
hyprctl reload
killall waybar; waybar &disown
```

## Configuration

### Per-project apps

Place a `.hyprcomp.toml` in any project root:

```toml
[[windows]]
exec = "claude"
terminal = true     # Wrap in alacritty

[[windows]]
exec = "chromium"
browser = true      # Isolated --user-data-dir per project

[[windows]]
exec = "nvim"
terminal = true
# cwd = "subdir"    # Optional: working dir relative to project root
```

Window types:
- `terminal = true` -- launched in alacritty with zsh
- `browser = true` -- gets `--user-data-dir` for per-project isolation
- `url_env = "VAR"` -- reads URL from the project's `.env` file
- Neither -- launched as a plain GUI app

### Subprojects

For monorepos, define subprojects that appear as separate entries in the launcher:

```toml
[[subprojects]]
path = "flux"

[[subprojects]]
path = "monorepo/apps/web"
name = "monorepo-web"
```

Subprojects nest recursively.

### Config resolution order

1. `<project_dir>/.hyprcomp.toml`
2. `~/.config/hyprcomp/defaults.toml`
3. Built-in defaults (claude, chromium, nvim)

## CLI reference

```
hyprcomp up|down|left|right   Navigate the grid
hyprcomp go <col>             Jump to column 1-10
hyprcomp move <col>           Move window to column 1-10
hyprcomp create <name>        Register a new project
hyprcomp delete               Delete current project
hyprcomp close                Close current project (with confirm)
hyprcomp rename <name>        Rename current project
hyprcomp list                 List all projects
hyprcomp status               Show current position
hyprcomp overview             Toggle workspace overview
hyprcomp restart              Restart overview daemon
```

## State files

| Path | Purpose |
|------|---------|
| `~/.config/hyprcomp/state` | Current row number |
| `~/.config/hyprcomp/projects` | Row-to-name mapping |
| `~/.config/hyprcomp/defaults.toml` | Global default windows config |
| `~/.config/hyprcomp/chromium/<name>/` | Isolated Chromium profiles |
| `~/.cache/hyprcomp/thumbs/` | Workspace screenshot cache |

## Uninstalling

1. Remove `source = ~/.config/hypr/hyprcomp.conf` from `hyprland.conf`
2. Restore default workspace gestures in your input config
3. Restore `"hyprland/workspaces"` in waybar config
4. `hyprctl reload && killall waybar && waybar &disown`
5. Remove `~/.config/hyprcomp/` and `~/.config/hypr/hyprcomp.conf`

## License

MIT
