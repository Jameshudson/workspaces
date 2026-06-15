#!/bin/zsh
set -e

REPO="https://github.com/Jameshudson/workspaces"

info()    { printf "\033[34m→\033[0m %s\n" "$1"; }
success() { printf "\033[32m✓\033[0m %s\n" "$1"; }
warn()    { printf "\033[33m!\033[0m %s\n" "$1"; }

# ── Resolve dotfiles location ──────────────────────────────────────────────────
# When run via curl pipe, $0 is "zsh" — clone the repo first
if [[ "$0" == "zsh" || "$0" == "-zsh" || "$0" == "/bin/zsh" ]]; then
  DOTFILES="${WORKSPACES_DIR:-$HOME/.workspaces}"
  if [ ! -d "$DOTFILES/.git" ]; then
    info "Cloning workspaces repo to $DOTFILES..."
    git clone "$REPO" "$DOTFILES"
  fi
else
  DOTFILES="$(cd "$(dirname "$0")" && pwd)"
fi

# ── Homebrew ──────────────────────────────────────────────────────────────────
if ! command -v brew &>/dev/null; then
  info "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  [[ -f /opt/homebrew/bin/brew ]] && eval "$(/opt/homebrew/bin/brew shellenv)"
fi
success "Homebrew"

# ── Dependencies ──────────────────────────────────────────────────────────────
brew install tmux fzf
success "tmux $(tmux -V | cut -d' ' -f2), fzf $(fzf --version | cut -d' ' -f1)"

# ── tmux.conf ─────────────────────────────────────────────────────────────────
if [ -f "$HOME/.tmux.conf" ] && [ ! -L "$HOME/.tmux.conf" ]; then
  warn "Backing up existing ~/.tmux.conf to ~/.tmux.conf.bak"
  mv "$HOME/.tmux.conf" "$HOME/.tmux.conf.bak"
fi
ln -sf "$DOTFILES/tmux.conf" "$HOME/.tmux.conf"
success "~/.tmux.conf → $(basename $DOTFILES)/tmux.conf"

# ── tmux-picker ───────────────────────────────────────────────────────────────
mkdir -p "$HOME/.local/bin"
ln -sf "$DOTFILES/tmux-picker" "$HOME/.local/bin/tmux-picker"
chmod +x "$DOTFILES/tmux-picker"
success "~/.local/bin/tmux-picker → $(basename $DOTFILES)/tmux-picker"

# ── .zshrc snippet ────────────────────────────────────────────────────────────
ZSHRC="$HOME/.zshrc"
MARKER="# tmux-picker: prevent Terminal.app window restoration"
if ! grep -q "$MARKER" "$ZSHRC" 2>/dev/null; then
  info "Adding Terminal.app fix to ~/.zshrc..."
  printf "\n%s\n" "$MARKER" >> "$ZSHRC"
  printf '[[ "$(defaults read com.apple.Terminal NSQuitAlwaysSendsApplicationTerminateNotification 2>/dev/null)" == "1" ]] || \\\n  defaults write com.apple.Terminal NSQuitAlwaysSendsApplicationTerminateNotification -bool true\n' >> "$ZSHRC"
fi
success "~/.zshrc"

# ── Terminal.app: disable scrollback (conflicts with tmux copy-mode in single pane) ──
_term_plist=$(mktemp)
if defaults export com.apple.Terminal "$_term_plist" 2>/dev/null; then
  while IFS= read -r _profile; do
    [[ -z "$_profile" ]] && continue
    /usr/libexec/PlistBuddy \
      -c "Set ':Window Settings:${_profile}:ScrollbackLines' 0" \
      "$_term_plist" 2>/dev/null \
      || /usr/libexec/PlistBuddy \
        -c "Add ':Window Settings:${_profile}:ScrollbackLines' integer 0" \
        "$_term_plist" 2>/dev/null \
      || true
    /usr/libexec/PlistBuddy \
      -c "Delete ':Window Settings:${_profile}:ScrollbackUnlimited'" \
      "$_term_plist" 2>/dev/null || true
  done < <(/usr/libexec/PlistBuddy -c "Print ':Window Settings:'" "$_term_plist" 2>/dev/null \
    | awk -F' = Dict \\{' '/ = Dict \{/ {gsub(/^[[:space:]]+/, "", $1); print $1}')
  defaults import com.apple.Terminal "$_term_plist"
  success "Terminal.app scrollback disabled"
fi
rm -f "$_term_plist"

# ── Done ──────────────────────────────────────────────────────────────────────
printf "\n\033[32mAll done!\033[0m Manual steps:\n\n"
printf "  Terminal.app → Settings → Profiles → Shell tab\n"
printf "  ☑ Run command: \033[1m~/.local/bin/tmux-picker\033[0m\n"
printf "  ☐ Run inside shell  (must be unchecked)\n\n"
printf "  Then restart Terminal.app for scrollback change to take effect.\n\n"
