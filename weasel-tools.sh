#!/usr/bin/env bash
# install-weasel-tools.sh — WSL2 automation for LabRat Mick’s dev setup

set -euo pipefail
IFS=$'\n\t'

readonly REPO_URL="${1:-https://github.com/labrat-0/weasel-tools.git}"
readonly CLONE_DIR="${2:-$HOME/weasel-tools}"
readonly CURRENT_USER="$(whoami)"

# ——— Helper Functions ——————————————————————————————
log()    { echo -e "\e[32m[INFO]\e[0m $*"; }
warn()   { echo -e "\e[33m[WARN]\e[0m $*"; }
err()    { echo -e "\e[31m[ERROR]\e[0m $*" >&2; exit 1; }
confirm() { read -r -p "$* [Y/n]: " reply; [[ $reply =~ ^([yY][eE]?[sS]?|)$ ]]; }

# ——— Confirm & Validate ——————————————————————————————
log "Starting LabRat weasel-tools setup"
warn "Press ENTER to continue or 'q' to abort"
read -r -n1 REPLY; echo
[[ $REPLY =~ [qQ] ]] && err "Setup aborted by user."

# Check for WSL2
if ! grep -qi 'microsoft' /proc/version; then
  err "❌ This script must be run inside WSL2!"
fi
log "✅ WSL2 detected"

# ——— Clone/update repo ——————————————————————————————
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

# Make script executable and symlink to ~/.local/bin
cd "$CLONE_DIR"
chmod +x weasel-tools.sh
mkdir -p "$HOME/.local/bin"
ln -sf "$PWD/weasel-tools.sh" "$HOME/.local/bin/weasel-tools"
export PATH="$HOME/.local/bin:$PATH"
log "Linked weasel-tools.sh → ~/.local/bin/weasel-tools"

# ——— System setup ————————————————————————————————
log "Updating system packages..."
sudo apt update && sudo apt upgrade -y

log "Installing core packages..."
sudo apt install -y software-properties-common
sudo apt install -y git curl build-essential unzip ripgrep fd-find cmake ranger zsh fzf tmux

# Symlink fdfind → fd if needed
if ! command -v fd &>/dev/null && command -v fdfind &>/dev/null; then
  ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
  log "Symlinked fdfind → fd"
fi

# Install Neovim from stable PPA
if ! command -v nvim &>/dev/null; then
  log "Adding Neovim stable PPA"
  sudo add-apt-repository -y ppa:neovim-ppa/stable
  sudo apt update
  sudo apt install -y neovim
fi

# Oh My Zsh setup
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  log "Installing Oh My Zsh"
  RUNZSH=no CHSH=no bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  sudo chsh -s "$(which zsh)" "$CURRENT_USER" || warn "Could not change default shell"
fi

# ——— Zsh customization ————————————————————————————————
ZSHRC="$HOME/.zshrc"
sed -i 's/^ZSH_THEME=.*/ZSH_THEME="robbyrussell"/' "$ZSHRC"
grep -qxF 'PROMPT="%~ %# "' "$ZSHRC" || echo 'PROMPT="%~ %# "' >> "$ZSHRC"

if ! grep -q "# LabRat Custom Aliases Start" "$ZSHRC"; then
  cat >> "$ZSHRC" << 'EOF'

# LabRat Custom Aliases Start
alias cdw='cd "/mnt/c" && nvim'
alias home='cd ~'
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
# LabRat Custom Aliases End
EOF
fi

# ——— Neovim config ————————————————————————————————
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

TFZF="$HOME/.local/share/nvim/lazy/telescope-fzf-native.nvim"
if [[ -d "$TFZF" ]]; then
  log "Building telescope-fzf-native..."
  (cd "$TFZF" && make) || warn "telescope-fzf-native build failed"
fi

# ——— Tmux setup ————————————————————————————————
log "Configuring tmux"
TMUX_DIR="$HOME/.tmux"
mkdir -p "$TMUX_DIR"
cat > "$TMUX_DIR/tmux.conf" << 'EOF'
# LabRat TMUX Config (prefix: C-a)
unbind C-b
set -g prefix C-a
bind C-a send-prefix
# Additional keybinds go here
EOF
ln -sf "$TMUX_DIR/tmux.conf" "$HOME/.tmux.conf"

# ——— Docs ————————————————————————————————
log "Writing keybindings reference to ~/keybindings.md"
cat > "$HOME/keybindings.md" << 'EOF'
# 🔑 LabRat Keybindings Overview
# Add your reference here
EOF

# ——— Wrap up ————————————————————————————————
log "✅ All done!"
echo
echo "➡️  Run 'zsh' to start using your new shell (if not already default)"
echo "➡️  Use 'weasel-tools' to launch your tool script anytime"
echo "➡️  Use 'nvim', 'tmux', etc. as configured"
