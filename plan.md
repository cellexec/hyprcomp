# HyprComp - 2D Project-Based Workspace Grid for Hyprland

## Problem

Working on many projects simultaneously (each with a terminal, browser, etc.) leads to confusion when switching between them. Hyprland's default workspace model is a flat, linear list with no concept of grouping windows by project.

## Vision

A 2D workspace grid where:
- **Horizontal axis (columns)**: windows within a project (terminal, browser, editor, etc.)
- **Vertical axis (rows)**: different projects
- **3-finger horizontal swipe**: smooth transition between windows in current project (clamped to row boundaries)
- **SUPER+CTRL+UP/DOWN**: switch between projects (same column position preserved)
- **SUPER+1-9**: project-relative workspace switching (goes to column N of current project row)

```
                 Window 1      Window 2      Window 3
Project A:       ws 1          ws 2          ws 3
Project B:       ws 11         ws 12         ws 13
Project C:       ws 21         ws 22         ws 23
```

## Current Setup (omarchy)

- Hyprland with omarchy defaults
- `gesture = 3, horizontal, workspace` for native horizontal swipe (already working)
- SUPER+1-9 bound to workspaces 1-10 via omarchy defaults (will be overridden)
- 4-finger gestures used for tmux window switching
- Workspace animations disabled by omarchy default (`animation = workspaces, 0, 0, ease`)

## Architecture

### Workspace Numbering Convention

Each project gets a "row" of 10 workspace slots:

| Project | Workspaces | Row ID |
|---------|-----------|--------|
| Row 0   | 1-10      | 0      |
| Row 1   | 11-20     | 1      |
| Row 2   | 21-30     | 2      |
| Row 3   | 31-40     | 3      |
| ...     | ...       | ...    |

Column position = `workspace % 10` (or 10 if remainder is 0)
Row = `(workspace - 1) / 10` (integer division)

### Components

#### 1. `hyprcomp` - CLI (bash script)

A script at `~/projects/hyprcomp/hyprcomp` that:

- Tracks current row (project) and column (window position) via a persistent state file (`~/.config/hyprcomp/state`)
- Project registry stored in `~/.config/hyprcomp/projects`
- Provides commands:
  - `hyprcomp up` - switch to same column in previous project row
  - `hyprcomp down` - switch to same column in next project row
  - `hyprcomp go <column>` - switch to column N of current project row (for SUPER+1-9)
  - `hyprcomp status` - show current project/column
  - `hyprcomp list` - list all project rows with names
  - `hyprcomp create <name>` - register a new project row
  - `hyprcomp rename <name>` - rename current project row
  - `hyprcomp delete` - unregister a project row
- Calculates target workspace: `(target_row * 10) + current_column`
- Dispatches via `hyprctl dispatch workspace <n>`
- Syncs with actual Hyprland workspace on every invocation via `hyprctl activeworkspace`

State file format (`~/.config/hyprcomp/state`):
```
current_row=1
```

Projects file format (`~/.config/hyprcomp/projects`):
```
0:homelab
1:guitar-studio
2:cooking-book
```

#### 2. Row Boundary Enforcement

Horizontal swipe (`gesture = 3, horizontal, workspace`) and SUPER+TAB use relative workspace navigation (`e+1`/`e-1`) which can leak across project row boundaries. To prevent this:

- Override SUPER+TAB and SUPER+SHIFT+TAB to use `hyprcomp` for row-aware navigation
- For 3-finger horizontal swipe: Hyprland's built-in gesture can't be intercepted, but since it only moves +/-1 workspace at a time, boundary leaking requires being at the exact edge of a row. Accept this limitation for now — a future `hyprgrass`-based solution can enforce boundaries properly.

#### 3. Hyprland Config (`~/.config/hypr/hyprcomp.conf`)

Sourced from `hyprland.conf`. Contains:

```conf
# Project switching keybindings
bindd = SUPER CTRL, UP, Previous project, exec, ~/projects/hyprcomp/hyprcomp up
bindd = SUPER CTRL, DOWN, Next project, exec, ~/projects/hyprcomp/hyprcomp down

# Project-relative SUPER+1-9 (overrides omarchy defaults)
bindd = SUPER, code:10, Switch to column 1, exec, ~/projects/hyprcomp/hyprcomp go 1
bindd = SUPER, code:11, Switch to column 2, exec, ~/projects/hyprcomp/hyprcomp go 2
bindd = SUPER, code:12, Switch to column 3, exec, ~/projects/hyprcomp/hyprcomp go 3
bindd = SUPER, code:13, Switch to column 4, exec, ~/projects/hyprcomp/hyprcomp go 4
bindd = SUPER, code:14, Switch to column 5, exec, ~/projects/hyprcomp/hyprcomp go 5
bindd = SUPER, code:15, Switch to column 6, exec, ~/projects/hyprcomp/hyprcomp go 6
bindd = SUPER, code:16, Switch to column 7, exec, ~/projects/hyprcomp/hyprcomp go 7
bindd = SUPER, code:17, Switch to column 8, exec, ~/projects/hyprcomp/hyprcomp go 8
bindd = SUPER, code:18, Switch to column 9, exec, ~/projects/hyprcomp/hyprcomp go 9
bindd = SUPER, code:19, Switch to column 10, exec, ~/projects/hyprcomp/hyprcomp go 10

# Project-relative move window (overrides omarchy defaults)
bindd = SUPER SHIFT, code:10, Move window to column 1, exec, ~/projects/hyprcomp/hyprcomp move 1
bindd = SUPER SHIFT, code:11, Move window to column 2, exec, ~/projects/hyprcomp/hyprcomp move 2
bindd = SUPER SHIFT, code:12, Move window to column 3, exec, ~/projects/hyprcomp/hyprcomp move 3
bindd = SUPER SHIFT, code:13, Move window to column 4, exec, ~/projects/hyprcomp/hyprcomp move 4
bindd = SUPER SHIFT, code:14, Move window to column 5, exec, ~/projects/hyprcomp/hyprcomp move 5
bindd = SUPER SHIFT, code:15, Move window to column 6, exec, ~/projects/hyprcomp/hyprcomp move 6
bindd = SUPER SHIFT, code:16, Move window to column 7, exec, ~/projects/hyprcomp/hyprcomp move 7
bindd = SUPER SHIFT, code:17, Move window to column 8, exec, ~/projects/hyprcomp/hyprcomp move 8
bindd = SUPER SHIFT, code:18, Move window to column 9, exec, ~/projects/hyprcomp/hyprcomp move 9
bindd = SUPER SHIFT, code:19, Move window to column 10, exec, ~/projects/hyprcomp/hyprcomp move 10
```

#### 4. Waybar Integration (optional, later)

Show current project name in waybar via a custom module that reads the state file.

## Implementation Plan

### Phase 1: Core Script (testable from terminal)

1. Write `~/projects/hyprcomp/hyprcomp` bash script
   - `up` / `down` commands calculate target workspace and dispatch
   - `go <column>` for project-relative workspace switching
   - `move <column>` for moving windows to project-relative workspaces
   - `status` shows current row + column
   - `create` / `list` / `rename` / `delete` for project management
   - State stored in `~/.config/hyprcomp/state`, projects in `~/.config/hyprcomp/projects`
   - Syncs with actual Hyprland workspace on every invocation via `hyprctl activeworkspace`

2. Test from terminal:
   - `hyprcomp create homelab` -> registers row 0
   - `hyprcomp create guitar-studio` -> registers row 1
   - `hyprcomp down` -> switches to workspace 11 (row 1, col 1)
   - `hyprcomp up` -> switches back to workspace 1 (row 0, col 1)
   - Switch to workspace 2 manually, then `hyprcomp down` -> goes to workspace 12
   - `hyprcomp go 3` -> goes to column 3 of current row

### Phase 2: Keybindings

3. Create `~/.config/hypr/hyprcomp.conf` with:
   - SUPER+CTRL+UP/DOWN bindings for project switching
   - SUPER+1-9 overrides for project-relative column switching
   - SUPER+SHIFT+1-9 overrides for project-relative window moving
4. Add `source = ~/.config/hypr/hyprcomp.conf` to `hyprland.conf` (at the end, after all other sources, so overrides take effect)
5. `hyprctl reload` to test

### Phase 3: Vertical Gestures (future)

6. Research `hyprgrass` plugin compatibility with current Hyprland version
7. If viable, configure 3-finger vertical swipe to call `hyprcomp up/down`
8. Also use `hyprgrass` to enforce horizontal swipe row boundaries
9. Do NOT use `libinput-gestures` — it conflicts with Hyprland's input device grabbing

### Phase 4: Polish

10. Waybar module showing current project name
11. Handle edge cases: wrapping, empty rows, manual workspace jumps
12. Startup script to restore last session's project layout

## Safe Testing Strategy

- Phase 1 is entirely safe: just a bash script calling `hyprctl dispatch`
- Phase 2 uses a separate sourced config file: remove the `source` line + `hyprctl reload` to revert
- SUPER+1-9 overrides work because `hyprcomp.conf` is sourced last — removing the source line restores omarchy defaults immediately
- Live-test bindings with `hyprctl keyword` before committing to files
- Back up config: `cp -r ~/.config/hypr ~/.config/hypr.bak` before Phase 2
- No animation changes — keeping omarchy's default disabled workspace animations to avoid side effects

## Decisions

- SUPER+1-9 are project-relative (SUPER+1 = column 1 of current row)
- State persisted in `~/.config/hyprcomp/` (survives reboots)
- No workspace animation overrides (avoids applying slidevert to all transitions)
- Horizontal swipe boundary leaking accepted as minor limitation until hyprgrass
- Max 9 project rows (workspaces 1-90)
- Vertical gestures deferred to Phase 3, keybindings only initially
