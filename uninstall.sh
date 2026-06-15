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

# ── Terminal.app settings ─────────────────────────────────────────────────────
defaults delete com.apple.Terminal NSQuitAlwaysSendsApplicationTerminateNotification 2>/dev/null || true
_term_plist=$(mktemp)
if defaults export com.apple.Terminal "$_term_plist" 2>/dev/null; then
  _default=$(/usr/libexec/PlistBuddy -c "Print ':Default Window Settings'" "$_term_plist" 2>/dev/null)
  if [[ -n "$_default" ]]; then
    /usr/libexec/PlistBuddy -c "Set ':Window Settings:${_default}:HasCommandString' false" "$_term_plist" 2>/dev/null || true
    /usr/libexec/PlistBuddy -c "Delete ':Window Settings:${_default}:CommandString'" "$_term_plist" 2>/dev/null || true
    defaults import com.apple.Terminal "$_term_plist"
  fi
fi
rm -f "$_term_plist"
success "Restored Terminal.app defaults"

# ── Done ──────────────────────────────────────────────────────────────────────
printf "\n\033[32mUninstalled.\033[0m Restart Terminal.app to apply.\n"
printf "tmux and fzf were left in place — remove manually if needed.\n\n"
