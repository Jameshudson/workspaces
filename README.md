# workspaces

A tmux launcher for macOS Terminal.app. Each new tab picks a layout and working directory, then drops you into a fresh tmux session. The session is destroyed when the tab closes.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/Jameshudson/workspaces/main/install.sh | zsh
```

### After installing

**Restart Terminal.app** to apply the settings.

### Clone manually instead

```bash
git clone https://github.com/Jameshudson/workspaces ~/.workspaces
~/.workspaces/install.sh
```

Set a custom clone location with:

```bash
WORKSPACES_DIR=~/my-location curl -fsSL https://raw.githubusercontent.com/Jameshudson/workspaces/main/install.sh | zsh
```

## Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/Jameshudson/workspaces/main/uninstall.sh | zsh
```

Then uncheck **Run command** in Terminal.app Settings → Profiles → Shell.

## Usage

Opening a new tab prompts for:
1. **Layout** — single panel, side by side, one left + two right, or 2×2 grid
2. **Directory** — fuzzy-search your home directory tree

Scroll through pane history with the mouse wheel (enters tmux copy mode). Press `q` to exit.

## What gets installed

| File | Location |
|------|----------|
| `tmux-picker` | `~/.local/bin/tmux-picker` (symlink) |
| `tmux.conf` | `~/.tmux.conf` (symlink) |
