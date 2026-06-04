#!/bin/zsh
set -e

info()    { printf "\033[34m→\033[0m %s\n" "$1"; }
success() { printf "\033[32m✓\033[0m %s\n" "$1"; }
warn()    { printf "\033[33m!\033[0m %s\n" "$1"; }

warn "This will remove tmux-picker, tmux.conf, and the .zshrc snippet."
printf "Continue? [y/N] "
read -r confirm
[[ "$confirm" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 0; }

# ── tmux-picker ───────────────────────────────────────────────────────────────
if [ -L "$HOME/.local/bin/tmux-picker" ]; then
  rm "$HOME/.local/bin/tmux-picker"
  success "Removed ~/.local/bin/tmux-picker"
fi

# ── tmux.conf ─────────────────────────────────────────────────────────────────
if [ -L "$HOME/.tmux.conf" ]; then
  rm "$HOME/.tmux.conf"
  if [ -f "$HOME/.tmux.conf.bak" ]; then
    mv "$HOME/.tmux.conf.bak" "$HOME/.tmux.conf"
    success "Restored ~/.tmux.conf from backup"
  else
    success "Removed ~/.tmux.conf"
  fi
fi

# ── .zshrc snippet ────────────────────────────────────────────────────────────
ZSHRC="$HOME/.zshrc"
MARKER="# tmux-picker: prevent Terminal.app window restoration"
if grep -q "$MARKER" "$ZSHRC" 2>/dev/null; then
  # Remove the marker line and the defaults write line after it
  sed -i '' "/$MARKER/,+2d" "$ZSHRC"
  success "Cleaned ~/.zshrc"
fi

# ── Terminal.app setting ──────────────────────────────────────────────────────
defaults delete com.apple.Terminal NSQuitAlwaysSendsApplicationTerminateNotification 2>/dev/null || true
success "Restored Terminal.app defaults"

# ── Done ──────────────────────────────────────────────────────────────────────
printf "\n\033[32mUninstalled.\033[0m\n"
printf "tmux, fzf, and TPM were left in place — remove manually if needed.\n\n"
printf "  Terminal.app → Settings → Profiles → Shell tab\n"
printf "  Uncheck 'Run command' to restore default shell behaviour\n\n"
