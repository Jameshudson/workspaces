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

# ── Terminal.app: disable window restoration ──────────────────────────────────
defaults write com.apple.Terminal NSQuitAlwaysSendsApplicationTerminateNotification -bool true
success "Terminal.app window restoration disabled"

# ── Terminal.app: profile settings ────────────────────────────────────────────
_term_plist=$(mktemp)
if defaults export com.apple.Terminal "$_term_plist" 2>/dev/null; then
  # Disable scrollback for all profiles (conflicts with tmux copy-mode in single pane)
  while IFS= read -r _prof; do
    [[ -z "$_prof" ]] && continue
    /usr/libexec/PlistBuddy \
      -c "Set ':Window Settings:${_prof}:ScrollbackLines' 0" \
      "$_term_plist" 2>/dev/null \
      || /usr/libexec/PlistBuddy \
        -c "Add ':Window Settings:${_prof}:ScrollbackLines' integer 0" \
        "$_term_plist" 2>/dev/null \
      || true
    /usr/libexec/PlistBuddy \
      -c "Delete ':Window Settings:${_prof}:ScrollbackUnlimited'" \
      "$_term_plist" 2>/dev/null || true
  done < <(/usr/libexec/PlistBuddy -c "Print ':Window Settings:'" "$_term_plist" 2>/dev/null \
    | awk -F' = Dict \\{' '/ = Dict \{/ {gsub(/^[[:space:]]+/, "", $1); print $1}')

  # Configure default profile to run tmux-picker directly (no intermediate shell)
  _default=$(/usr/libexec/PlistBuddy -c "Print ':Default Window Settings'" "$_term_plist" 2>/dev/null)
  if [[ -n "$_default" ]]; then
    /usr/libexec/PlistBuddy -c "Set ':Window Settings:${_default}:CommandString' $HOME/.local/bin/tmux-picker" "$_term_plist" 2>/dev/null \
      || /usr/libexec/PlistBuddy -c "Add ':Window Settings:${_default}:CommandString' string $HOME/.local/bin/tmux-picker" "$_term_plist" 2>/dev/null || true
    /usr/libexec/PlistBuddy -c "Set ':Window Settings:${_default}:HasCommandString' true" "$_term_plist" 2>/dev/null \
      || /usr/libexec/PlistBuddy -c "Add ':Window Settings:${_default}:HasCommandString' bool true" "$_term_plist" 2>/dev/null || true
    /usr/libexec/PlistBuddy -c "Set ':Window Settings:${_default}:RunCommandAsShell' false" "$_term_plist" 2>/dev/null \
      || /usr/libexec/PlistBuddy -c "Add ':Window Settings:${_default}:RunCommandAsShell' bool false" "$_term_plist" 2>/dev/null || true
  fi

  defaults import com.apple.Terminal "$_term_plist"
  success "Terminal.app configured"
fi
rm -f "$_term_plist"

# ── Done ──────────────────────────────────────────────────────────────────────
printf "\n\033[32mAll done!\033[0m Restart Terminal.app to apply.\n\n"
