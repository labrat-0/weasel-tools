# 🧪 LabRat Mick's WEASEL Tools Setup

*Supercharge your Windows 11 WSL2(Weasel😆) Ubuntu LTS environment* 🚀

## 🎯 Overview

This project provides an automated setup script to configure a powerful and personalized environment within WSL2 on Windows 11, based on Ubuntu LTS.

### ✨ Features

- 📝 Latest Neovim with productivity-boosting plugins
- 🖥️ Custom tmux config with intuitive keybindings
- 🐚 Zsh shell with smart aliases and a clean prompt
- 🛠️ Essential CLI tools (Ranger, fzf, ripgrep, and more)
- 📚 Auto-generated keybindings reference (`keybinds.md`)

## ⚠️ Important Note

This setup script is designed for use in a secure, controlled environment where you have appropriate permissions. While the script automates installations and configuration to save time, it's recommended to backup important data before running it.

> 🔒 LabRat takes no responsibility for any unintended consequences; please use thoughtfully and adapt to your specific needs.

## 🚀 Installation & Usage

1. **Clone this repository:**
   ```bash
   git clone https://github.com/labrat-0/weasel-tools.git
   cd weasel-tools/
   ```

2. **Run the setup script:**
  
   ```bash
   chmod +x weasel-tools.sh
   ./weasel-tools.sh
   ```

4. **Follow the prompt:**
   - Press `Enter` to begin the setup
   - Press `q` to abort

5. **Post-installation:**
   - Restart your terminal or run `source ~/.zshrc` to activate aliases
   - Launch tmux with `tmux`
   - Open Neovim with `nvim`
   - View keybindings anytime via `nvim ~/keybinds.md`

## 🎮 Keybindings & Aliases

The script generates a comprehensive `~/keybinds.md` file covering:

- 🪟 Tmux window and pane management
- ⌨️ Neovim navigation (Telescope & Harpoon)
- 📁 Zsh navigation aliases and safer file commands
- 📊 System monitoring shortcuts
- 🔍 Fuzzy finder (fzf) helpers
- 🎨 Fun extras!

## 🛠️ Customization & Contributions

Feel free to customize:

- `~/.tmux/tmux.conf` - Tweak tmux keybindings and appearance
- `~/.config/nvim/init.lua` - Manage Neovim plugins and keys
- `~/.zshrc` - Extend or modify shell aliases and prompt

💡 Pull requests and suggestions are very welcome!

## 📜 License

MIT License © LabRat 🐀

*Inspired by ThePrimeagen's setup for faster productivity* 🔥

---

<div align="center">

Made with ❤️ by Mick

**LabRat Mick's WEASEL Tools — Your MS WSL2 Environment Starter Kit**

</div>
