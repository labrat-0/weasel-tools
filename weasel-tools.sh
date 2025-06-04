#!/bin/bash

# LabRat Mick's WEASEL Tools Setup

echo "labrat weasel tools setup"
echo "Press ENTER to continue or q to abort."
read -r -n1 input
if [[ $input == "q" || $input == "Q" ]]; then
  echo "Setup aborted."
  exit 1
fi

# Check if running inside WSL2
if ! grep -qEi "(Microsoft|WSL)" /proc/version &> /dev/null; then
  echo "❌ WSL2 not detected. Please run this script inside WSL2."
  exit 1
fi

echo "✅ WSL2 detected, proceeding..."

# Update & upgrade system
sudo apt update && sudo apt upgrade -y

# Install dependencies
sudo apt install -y git curl unzip build-essential ripgrep fd-find cmake ranger zsh fzf tmux

# Fix fd symlink for fd-find
if ! command -v fd &> /dev/null && command -v fdfind &> /dev/null; then
  mkdir -p ~/.local/bin
  ln -sf "$(which fdfind)" ~/.local/bin/fd
  export PATH="$HOME/.local/bin:$PATH"
fi

# Install Neovim latest stable via PPA
sudo add-apt-repository -y ppa:neovim-ppa/stable
sudo apt update
sudo apt install -y neovim

# Install Oh My Zsh if missing
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  echo "Installing Oh My Zsh..."
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  chsh -s "$(which zsh)"
fi

# Set minimal prompt and theme in .zshrc
sed -i 's/^ZSH_THEME=.*/ZSH_THEME="robbyrussell"/' ~/.zshrc
grep -q 'PROMPT="%~ %# "' ~/.zshrc || echo 'PROMPT="%~ %# "' >> ~/.zshrc

# Append your custom aliases to .zshrc (avoid duplicates)
grep -qxF "# LabRat Custom Aliases Start" ~/.zshrc || cat >> ~/.zshrc << 'EOF'

# LabRat Custom Aliases Start

alias cdw='cd "/mnt/c" && nvim'
alias cdh='cd "/mnt/c" && nvim'
alias cdc='cd /mnt/c && nvim'
alias cdd='cd /mnt/c && nvim'
alias home='cd ~'

# Safer File Operations
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# Fun & Feedback Aliases
alias update='sudo apt update && sudo apt upgrade -y && echo -e "\e[32m🎉 System updated successfully!\e[0m"'
alias cls='clear && echo -e "\e[36m🧹 Screen cleared!\e[0m"'
alias reload='source ~/.zshrc && echo -e "\e[33m🔁 Zsh reloaded!\e[0m"'

# System Monitoring
alias duh='du -sh * | sort -h'
alias memtop='ps aux --sort=-%mem | head -n 10'
alias ports='sudo lsof -i -P -n | grep LISTEN'

# Extras
alias moo='fortune | cowsay'
alias weather='curl wttr.in'
alias cal='cal -w'

# Fuzzy Finder Aliases (requires fzf)
alias ff='find . -type f | fzf'
alias fd='cd "$(find . -type d | fzf)"'

# LabRat Custom Aliases End

EOF

# Setup Neovim config and plugins

mkdir -p ~/.config/nvim/lua/plugins
mkdir -p ~/.config/nvim

cat > ~/.config/nvim/init.lua << 'EOF'
vim.g.mapleader = " "

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    lazypath,
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

require("telescope").setup{}
require("telescope").load_extension("fzf")

vim.keymap.set("n", "<leader>ff", "<cmd>Telescope find_files<CR>", { desc = "Find files" })
vim.keymap.set("n", "<leader>fg", "<cmd>Telescope live_grep<CR>", { desc = "Live grep" })
vim.keymap.set("n", "<leader>fb", "<cmd>Telescope buffers<CR>", { desc = "Buffers" })
vim.keymap.set("n", "<leader>fh", "<cmd>Telescope help_tags<CR>", { desc = "Help tags" })

local harpoon = require("harpoon")
local harpoon_ui = require("harpoon.ui")

vim.keymap.set("n", "<leader>a", require("harpoon.mark").add_file, { desc = "Harpoon add file" })
vim.keymap.set("n", "<C-e>", harpoon_ui.toggle_quick_menu, { desc = "Harpoon menu" })
vim.keymap.set("n", "<leader>1", function() harpoon_ui.nav_file(1) end)
vim.keymap.set("n", "<leader>2", function() harpoon_ui.nav_file(2) end)
vim.keymap.set("n", "<leader>3", function() harpoon_ui.nav_file(3) end)
vim.keymap.set("n", "<leader>4", function() harpoon_ui.nav_file(4) end)

vim.keymap.set("n", "<leader>r", ":!ranger<CR>", { desc = "Open Ranger" })
EOF

# Sync plugins and build telescope-fzf-native
nvim --headless "+Lazy sync" "+qall"
cd ~/.local/share/nvim/lazy/telescope-fzf-native.nvim && make || true

# Setup tmux config directory & file
mkdir -p ~/.tmux
cat > ~/.tmux/tmux.conf << 'EOF'
# LabRat Mick's TMUX Config

# Prefix key
unbind C-b
set-option -g prefix C-a
bind-key C-a send-prefix

# Window management
bind c new-window
bind , command-prompt "rename-window %%"
bind -n M-Right next-window
bind -n M-Left previous-window

# Pane management
bind h split-window -h
bind j split-window -v

bind -n C-Left select-pane -L
bind -n C-Right select-pane -R
bind -n C-Up select-pane -U
bind -n C-Down select-pane -D

# Resize panes with Ctrl+Plus and Ctrl+Minus
bind -n C-+ resize-pane -R 5
bind -n C-- resize-pane -L 5

# Close pane with Ctrl+d (send exit)
bind C-d send-keys C-d

EOF

# Symlink tmux config to home
ln -sf ~/.tmux/tmux.conf ~/.tmux.conf

# Create keybindings markdown reference file in home directory
cat > ~/keybindings.md << 'EOF'
# 🔑 Keybindings & Aliases Reference for Neovim, Tmux, Zsh, Ranger

---

## 🪟 Window Management (tmux)

| Action                | Keybind       | Description                |
|-----------------------|---------------|----------------------------|
| Create new window     | Ctrl+a c      | Create a new tmux window   |
| Switch to next window | Alt + →      | Move to next window        |
| Switch to prev window | Alt + ←      | Move to previous window    |
| Rename window         | Ctrl+a ,      | Rename current window      |

---

## 🧱 Pane Management (tmux)

| Action              | Keybind           | Description                      |
|---------------------|-------------------|----------------------------------|
| Horizontal split    | Ctrl + h          | Split pane left/right            |
| Vertical split      | Ctrl + j          | Split pane top/bottom            |
| Move to left pane   | Ctrl + ←          | Navigate to left pane            |
| Move to right pane  | Ctrl + →          | Navigate to right pane           |
| Move to upper pane  | Ctrl + ↑          | Navigate to upper pane           |
| Move to lower pane  | Ctrl + ↓          | Navigate to lower pane           |
| Resize pane         | Ctrl + + / Ctrl + -| Resize pane horizontally         |
| Close pane          | Ctrl + d          | Exit shell / close pane          |

---

## 🧑‍💻 Neovim Navigation

### Telescope

| Action            | Keybind       | Description             |
|-------------------|---------------|-------------------------|
| Find files        | <leader> ff   | File finder             |
| Live grep         | <leader> fg   | Search contents         |
| List buffers      | <leader> fb   | Open buffers list       |
| Help tags         | <leader> fh   | Neovim help tags        |

### Harpoon v2

| Action             | Keybind          | Description                   |
|--------------------|------------------|-------------------------------|
| Add file           | <leader> a       | Bookmark current file         |
| Open Harpoon menu  | Ctrl + e         | Toggle quick menu             |
| Jump to file 1-4   | <leader> 1-4     | Jump to bookmarked file       |

### Ranger (CLI file explorer)

| Action             | Keybind       | Description                   |
|--------------------|---------------|-------------------------------|
| Open Ranger        | <leader> r    | Open CLI file explorer        |

---

## ⚙️ Terminal / Shell (Zsh)

| Feature          | Setting                      |
|------------------|------------------------------|
| Prompt           | `%~ %#` (short current path) |
| Shell            | Zsh with Oh My Zsh           |
| Theme            | `robbyrussell` (minimal)     |

---

## 🚀 Navigation Aliases to Windows File Explorer

| Alias  | Command                                                                                 | Description                             |
|--------|-----------------------------------------------------------------------------------------|-----------------------------------------|
| cdw    | `cd "/mnt/c" && nvim` | Go to Path and open Neovim    |
| cdh    | `cd "/mnt/c" && nvim`                                                    | Go to Path and open Neovim       |
| cdc    | `cd "/mnt/c" && nvim`                                                                     | Go to Path and open Neovim  |
| cdd    | `cd "/mnt/c/" && nvim`                                            | Go to Path and open Neovim  |
| home   | `cd ~`                                                                                  | Go to home directory                    |

---

## 🛡️ Safer File Operations (Interactive)

| Alias  | Command   | Description                        |
|--------|-----------|-----------------------------------|
| rm     | `rm -i`   | Remove files with confirmation    |
| cp     | `cp -i`   | Copy files with confirmation      |
| mv     | `mv -i`   | Move files with confirmation      |

---

## 🎉 Fun & Feedback Aliases

| Alias  | Command                                                                                   | Description                        |
|--------|-------------------------------------------------------------------------------------------|----------------------------------|
| update | `sudo apt update && sudo apt upgrade -y && echo -e "\e[32m🎉 System updated successfully!\e[0m"` | Update system with success message |
| cls    | `clear && echo -e "\e[36m🧹 Screen cleared!\e[0m"`                                        | Clear screen with colorful message |
| reload | `source ~/.zshrc && echo -e "\e[33m🔁 Zsh reloaded!\e[0m"`                               | Reload shell config with feedback  |

---

## 📊 System Monitoring

| Alias  | Command                       | Description                 |
|--------|-------------------------------|-----------------------------|
| duh    | `du -sh * | sort -h`           | Disk usage sorted by size   |
| memtop | `ps aux --sort=-%mem | head -n 10` | Top 10 memory-consuming processes |
| ports  | `sudo lsof -i -P -n | grep LISTEN` | List listening ports        |

---

## ✨ Extras

| Alias   | Command       | Description                   |
|---------|---------------|-------------------------------|
| moo     | `fortune | cowsay` | Fun fortune cookie with cow   |
| weather | `curl wttr.in` | Show weather forecast         |
| cal     | `cal -w`     | Calendar with week numbers     |

---

## 🔍 Fuzzy Finder Aliases (requires fzf)

| Alias | Command                   | Description                    |
|-------|---------------------------|--------------------------------|
| ff    | `find . -type f | fzf`   | Fuzzy find files in current dir|
| fd    | `cd "$(find . -type d | fzf)"` | Fuzzy cd into directory          |

---

## Notes

- `<leader>` is Spacebar (` `) in Neovim keybinds.
- Use `Ctrl` = `<C-...>`, e.g. `Ctrl+e` = `<C-e>`.
- Save this file as `~/keybindings.md` and open in Neovim with `:e ~/keybindings.md`.
- Preview in Ranger by selecting and pressing `l`.
- Customize and add aliases/plugins as you go.

---
EOF

echo "✅ Created ~/keybindings.md with your full keybindings and aliases reference."

echo "✅ Setup complete! Made with ❤️ by Mick"
echo "👉 Restart your terminal or run 'source ~/.zshrc' to load aliases"
echo "👉 Start Neovim with 'nvim'"
echo "👉 Use 'tmux' to start your tmux session"
