#!/usr/bin/env bash
# install-weasel-tools.sh — WSL2-focused automation for LabRat Mick’s dev setup

set -euo pipefail
IFS=$'\n\t'

readonly REPO_URL="${1:-https://github.com/labrat-0/weasel-tools.git}"
readonly CLONE_DIR="${2:-$HOME/weasel-tools}"

# ——— Helper Functions ——————————————————————————————————————————————
log()    { echo -e "\e[32m[INFO]\e[0m $*"; }
warn()   { echo -e "\e[33m[WARN]\e[0m $*"; }
err()    { echo -e "\e[31m[ERROR]\e[0m $*" >&2; exit 1; }
confirm() { read -r -p "$* [Y/n]: " reply; [[ $reply =~ ^([yY][eE]?[sS]?|)$ ]]; }

# ——— Basic interactivity & checks ——————————————————————————————————
log "Starting LabRat weasel-tools setup"
warn "Press ENTER to continue or 'q' to abort"
read -r -n1 REPLY; echo
[[ $REPLY =~ [qQ] ]] && err "Setup aborted by user."

# Validate WSL2 environment
if ! grep -qi 'microsoft' /proc/version; then
  err "❌ This script must run inside WSL2 Ubuntu!"
fi
log "✅ WSL2 detected — good to go"

# ——— Clone/update your repo ———————————————————————————————————————
if [[ -d "$CLONE_DIR/.git" ]]; then
  log "Found existing clone at $CLONE_DIR"
  if confirm "Pull latest changes?"; then
    git -C "$CLONE_DIR" pull --ff-only
  fi
else
  rm -rf "$CLONE_DIR"
  log "Cloning $REPO_URL → $CLONE_DIR"
  git clone "$REPO_URL" "$CLONE_DIR"
fi

# Link/install script
cd "$CLONE_DIR"
chmod +x weasel-tools.sh
log "Executable bit set on weasel-tools.sh"

# Symlink to bin—easy access
mkdir -p "$HOME/.local/bin"
ln -sf "$PWD/weasel-tools.sh" "$HOME/.local/bin/weasel-tools"
log "Linked weasel-tools.sh → ~/.local/bin/weasel-tools"
export PATH="$HOME/.local/bin:$PATH"

# ——— System setup ————————————————————————————————————————————————
log "Updating system packages..."
sudo apt update && sudo apt upgrade -y

log "Installing core packages..."
sudo apt install -y git curl build-essential unzip ripgrep fd-find cmake ranger zsh fzf tmux

# Fix fd on Ubuntu (fd-find → fd)
if ! command -v fd &>/dev/null && command -v fdfind &>/dev/null; then
  ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
  log "Symlinked fdfind → fd"
fi

# Neovim via PPA
if ! command -v nvim &>/dev/null; then
  log "Adding Neovim stable PPA"
  sudo add-apt-repository -y ppa:neovim-ppa/stable
  sudo apt update
  sudo apt install -y neovim
fi

# Oh My Zsh
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  log "Installing Oh My Zsh"
  RUNZSH=no CHSH=no bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  sudo chsh -s "$(which zsh)" "$USER"
fi

# ——— Shell personalization ————————————————————————————————————————
ZSHRC="$HOME/.zshrc"
sed -i 's/^ZSH_THEME=.*/ZSH_THEME="robbyrussell"/' "$ZSHRC"
grep -qxF 'PROMPT="%~ %# "' "$ZSHRC" || echo 'PROMPT="%~ %# "' >> "$ZSHRC"

if ! grep -q "# LabRat Custom Aliases Start" "$ZSHRC"; then
  cat >> "$ZSHRC" << 'EOF'

# LabRat Custom Aliases Start
alias cdw='cd "/mnt/c" && nvim'
alias home='cd ~'
alias rm='rm -i'  # safer removal
alias cp='cp -i'
alias mv='mv -i'
...  # Your other aliases here
# LabRat Custom Aliases End
EOF
fi

# ——— Neovim configuration ————————————————————————————————————————
log "Configuring Neovim"
NVIM_CONF="$HOME/.config/nvim/init.lua"
mkdir -p "$(dirname "$NVIM_CONF")"
cat > "$NVIM_CONF" << 'EOF'
-- Minimal init.lua
vim.g.mapleader = " "
local lazypath = vim.fn.stdpath("data").."/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git","clone","--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)
require("lazy").setup({
  "nvim-lua/plenary.nvim",
  "nvim-tree/nvim-web-devicons",
  "nvim-telescope/telescope.nvim",
  "nvim-telescope/telescope-fzf-native.nvim",
  "ThePrimeagen/harpoon",
})
EOF

log "Syncing plugins..."
nvim --headless "+Lazy sync" "+qall" || warn "Plugin sync failed"

# Build telescope-fzf-native if present
TFZF="$HOME/.local/share/nvim/lazy/telescope-fzf-native.nvim"
if [[ -d "$TFZF" ]]; then
  log "Building telescope-fzf-native..."
  (cd "$TFZF" && make) || warn "telescope-fzf-native build failed"
fi

# ——— Tmux setup ————————————————————————————————————————————————
log "Configuring tmux"
TMUX_DIR="$HOME/.tmux"
mkdir -p "$TMUX_DIR"
cat > "$TMUX_DIR/tmux.conf" << 'EOF'
# LabRat TMUX Config (prefix: C-a)
unbind C-b
set -g prefix C-a
bind C-a send-prefix
...  # your tmux keybindings here
EOF
ln -sf "$TMUX_DIR/tmux.conf" "$HOME/.tmux.conf"

# ——— Documentation ————————————————————————————————————————————————
log "Writing keybindings reference to ~/keybindings.md"
cat > "$HOME/keybindings.md" << 'EOF'
# 🔑 LabRat Keybindings Overview
...  # your markdown reference here
EOF

log "✅ All done! Usage:"
echo "   - new shell → zsh"
echo "   - run 'weasel-tools' to launch your tools script"
echo "   - use 'nvim', 'tmux', etc., as configured"
