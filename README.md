# Dotfiles

A simple, modular zsh configuration system that's easy to understand and extend.

## Features

- Git-aware prompt - Shows current branch and status with color indicators
- Enhanced history - Shared across terminals with timestamps
- Useful aliases - Common shortcuts for navigation and file operations
- Zsh plugins - Autosuggestions and syntax highlighting
- FZF integration - Fuzzy finding for history, files, and directories (optional)
- Zoxide - Smart directory jumping based on frecency (optional)
- Machine-specific overrides - Local customizations without affecting shared config
- Cross-platform - Works on Debian, Ubuntu, Alpine, and Arch Linux

## Quick Start

First-time installation:

```bash
# Clone the repository
git clone <your-repo-url> ~/.dotfiles

# Install with core tools (zsh, fzf, zoxide, and plugins)
cd ~/.dotfiles
./install.sh --core-tools

# Change default shell to zsh
chsh -s $(which zsh)

# Reload your shell
exec zsh
```

Installation on new machine:

```bash
# Clone and install
git clone <your-repo-url> ~/.dotfiles
cd ~/.dotfiles
./install.sh

# Customize for this machine
vim ~/.dotfiles/local/zshrc_local
```

## Installation Options

- `./install.sh` - Basic installation
- `./install.sh --core-tools` - Install with zsh, fzf, zoxide, and plugins
- `./install.sh --full` - Enable full feature set (future enhancements)

## Repository Structure

```
~/.dotfiles/
├── README.md                    # This file
├── install.sh                   # Main installation script
│
├── core/                        # Core features (always loaded)
│   ├── zshrc                    # Main config loader
│   ├── prompt.zsh               # Git-aware prompt
│   ├── history.zsh              # History configuration
│   ├── aliases.zsh              # Basic aliases
│   ├── keybindings.zsh          # Keybindings and completion
│   └── fzf.zsh                  # FZF + Zoxide integration
│
├── full/                        # Optional advanced features
│   └── zshrc_full               # Additional configurations
│
├── local/                       # Per-machine overrides (gitignored)
│   ├── zshrc_local.example      # Template for local config
│   └── zshrc_local              # Your machine-specific settings
│
└── scripts/
    ├── setup-core.sh            # Install core tools
    ├── detect-os.sh             # OS detection helper
    └── backup.sh                # Backup existing dotfiles
```

## Customization

Machine-specific configuration:

Edit `~/.dotfiles/local/zshrc_local` for machine-specific settings:

```bash
# Custom aliases
alias work='cd ~/projects/work'
alias deploy='ssh user@production'

# Custom PATH
export PATH="$HOME/custom/bin:$PATH"

# Environment variables
export EDITOR="vim"
export PROJECT_DIR="$HOME/work"
```

Adding custom aliases:

Edit `~/.dotfiles/core/aliases.zsh` for aliases shared across all machines:

```bash
# Add your aliases here
alias myproject='cd ~/projects/myproject'
```

Modifying the prompt:

Edit `~/.dotfiles/core/prompt.zsh` to customize colors, format, or behavior.

## Prompt Features

The prompt shows:

```
╭─ user@hostname in ~/path on branch*
╰─❯
```

Where:
- user@hostname - Always visible (cyan) - useful for remote machines
- ~/path - Current directory, truncated to last 2 parts (blue)
- branch - Git branch with status (green if clean, yellow if dirty)
- ❯ - Prompt character (green if last command succeeded, red if failed)

Git status indicators:
- * - Uncommitted changes
- + - Staged changes
- No indicator - Clean working tree

## Key Bindings

With FZF:
- Ctrl+R - Search command history with fuzzy finder
- Ctrl+T - Search files in current directory
- Alt+C - Search directories and cd into selection

With Zoxide:
- z <directory> - Jump to frequently used directory

With Zsh:
- Up/Down arrows - Search history based on what you've typed
- Ctrl+Left/Right - Move by word
- Tab - Completion with menu selection

## Manual Tool Installation

If you didn't use --core-tools during installation, you can install them later:

```bash
# Install zsh, fzf, zoxide, and plugins (will prompt for sudo if needed)
bash ~/.dotfiles/scripts/setup-core.sh
```

Or install manually:

Zsh (Arch Linux):
```bash
sudo pacman -S zsh
chsh -s $(which zsh)
```

FZF (Arch Linux):
```bash
sudo pacman -S fzf
```

Zoxide (Arch Linux):
```bash
sudo pacman -S zoxide
```

Zsh plugins:
```bash
mkdir -p ~/.zsh
git clone https://github.com/zsh-users/zsh-autosuggestions ~/.zsh/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting ~/.zsh/zsh-syntax-highlighting
```

## Uninstallation

To uninstall:

```bash
# Restore your backup (if you have one)
cp /tmp/dotfiles_backup_*/.zshrc ~/.zshrc

# Or create a simple .zshrc
echo '# Basic zshrc' > ~/.zshrc

# Remove dotfiles
rm -rf ~/.dotfiles

# Reload shell
exec zsh
```

## Updating

```bash
cd ~/.dotfiles
git pull
exec zsh
```

## Troubleshooting

Prompt not showing colors:

Make sure your terminal supports colors. Test with:
```bash
echo -e "\033[0;32mGreen\033[0m \033[0;34mBlue\033[0m \033[0;31mRed\033[0m"
```

Git branch not showing:

Make sure you're in a git repository:
```bash
git status
```

FZF key bindings not working:

FZF might not be installed or sourced correctly. Check:
```bash
which fzf
```

Reinstall with:
```bash
bash ~/.dotfiles/scripts/setup-core.sh
```

Zoxide not working:

Make sure zoxide is installed:
```bash
which zoxide
```

After installing, reload your shell:
```bash
exec zsh
```

Autosuggestions not appearing:

Make sure the plugin is installed:
```bash
ls ~/.zsh/zsh-autosuggestions
```

If not, run:
```bash
bash ~/.dotfiles/scripts/setup-core.sh
```

## Contributing

This is a personal dotfiles repository, but feel free to fork and adapt it for your own use.

## License

MIT License - Feel free to use and modify as you wish.
