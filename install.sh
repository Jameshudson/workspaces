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

# ── TPM ───────────────────────────────────────────────────────────────────────
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
  info "Installing TPM..."
  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi
success "TPM"

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

# ── TPM plugins ───────────────────────────────────────────────────────────────
info "Installing tmux plugins (resurrect + continuum)..."
"$HOME/.tmux/plugins/tpm/bin/install_plugins" >/dev/null 2>&1
success "tmux plugins"

# ── .zshrc snippet ────────────────────────────────────────────────────────────
ZSHRC="$HOME/.zshrc"
MARKER="# tmux-picker: prevent Terminal.app window restoration"
if ! grep -q "$MARKER" "$ZSHRC" 2>/dev/null; then
  info "Adding Terminal.app fix to ~/.zshrc..."
  printf "\n%s\n" "$MARKER" >> "$ZSHRC"
  printf '[[ "$(defaults read com.apple.Terminal NSQuitAlwaysSendsApplicationTerminateNotification 2>/dev/null)" == "1" ]] || \\\n  defaults write com.apple.Terminal NSQuitAlwaysSendsApplicationTerminateNotification -bool true\n' >> "$ZSHRC"
fi
success "~/.zshrc"

# ── Done ──────────────────────────────────────────────────────────────────────
printf "\n\033[32mAll done!\033[0m One manual step:\n\n"
printf "  Terminal.app → Settings → Profiles → Shell tab\n"
printf "  ☑ Run command: \033[1m~/.local/bin/tmux-picker\033[0m\n"
printf "  ☐ Run inside shell  (must be unchecked)\n\n"
