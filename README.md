# workspaces

A tmux session manager for macOS Terminal.app. Replaces the default shell with an interactive picker for creating, restoring, and managing tmux sessions.

## Features

- Session picker on every new terminal tab
- Create sessions with a custom name, pane layout, and working directory
- Sessions sorted by last used
- Kill sessions with confirmation from the picker
- Auto-saves every 5 minutes + on new session creation
- Full restore on fresh start (layout, pane directories, scrollback history)
- Tab titles show the active session name

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/jameshudson/workspaces/main/install.sh | zsh
```

Then one manual step in Terminal.app:

**Settings → Profiles → Shell tab**
- Check **Run command**: `~/.local/bin/tmux-picker`
- Uncheck **Run inside shell**

### Clone manually instead

```bash
git clone https://github.com/jameshudson/workspaces ~/.workspaces
~/.workspaces/install.sh
```

Set a custom clone location with:

```bash
WORKSPACES_DIR=~/my-location curl -fsSL https://raw.githubusercontent.com/jameshudson/workspaces/main/install.sh | zsh
```

## Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/jameshudson/workspaces/main/uninstall.sh | zsh
```

Then uncheck **Run command** in Terminal.app Settings → Profiles → Shell.

## Usage

| Action | How |
|--------|-----|
| Attach to session | Select from picker + Enter |
| Create new session | Select "New session" |
| Kill session | `ctrl-x` in picker |
| Save sessions now | `prefix + ctrl-s` |
| Restore full layout | `prefix + ctrl-r` |

## What gets installed

| File | Location |
|------|----------|
| `tmux-picker` | `~/.local/bin/tmux-picker` (symlink) |
| `tmux.conf` | `~/.tmux.conf` (symlink) |
| TPM + plugins | `~/.tmux/plugins/` |
| Terminal.app fix | appended to `~/.zshrc` |
