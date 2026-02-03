# Dotfiles Repository

Zsh configuration with modular structure. Symlinks `core/zshrc` to `~/.zshrc`.

## Structure

```
install.sh          - Main installer, handles symlinks and backups
core/zshrc          - Entry point, sources all core/*.zsh files
core/prompt.zsh     - Git-aware two-line prompt with transient support
core/aliases.zsh    - Shell aliases
core/keybindings.zsh - Zsh key bindings
core/fzf.zsh        - Fzf integration and config
core/history.zsh    - History settings
local/zshrc_local   - Machine-specific config (gitignored), migrated from existing ~/.zshrc
scripts/setup-core.sh - Installs dependencies (zsh, fzf, starship, etc)
scripts/detect-os.sh  - OS detection helper
scripts/backup.sh     - Backup utility
```

## Prompt

`core/prompt.zsh` implements custom prompt. Uses single `git status --porcelain=v2 --branch` call for all git info. Features:
- Two-line format with user@host, path, git branch
- Yellow branch = dirty, green = clean
- Arrows for ahead/behind remote
- Transient prompt (collapses after command execution)
- Path truncation with `…/` indicator (e.g., `~/…/bar/baz`)

Key functions: `__git_prompt_info`, `__build_prompt`, `__truncate_path`

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `TRUNCATE_PROMPT` | `0` | Set to `1` to enable path truncation |

Add to `local/zshrc_local` to customize:
```zsh
export TRUNCATE_PROMPT=1  # Enable truncated paths (e.g., ~/…/bar/baz)
```

## Local Customization

`local/zshrc_local` is sourced if exists, not tracked in git. Use for machine-specific PATH, env vars, aliases.

## NixOS Support

NixOS users have native declarative configuration via Nix flakes. Two modes are supported:

### Mode 1: Declarative (Recommended for NixOS)

Fully declarative - dotfiles sourced from Nix store, no git clone needed. Perfect for reproducible systems.

#### Installation

1. Add to `/etc/nixos/flake.nix`:
```nix
{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    dotfiles.url = "github:yourusername/dotfiles";
    # Or pin to specific branch/tag:
    # dotfiles.url = "github:yourusername/dotfiles?ref=main";
    # dotfiles.url = "github:yourusername/dotfiles?ref=v1.0.0";
  };

  outputs = { self, nixpkgs, dotfiles, ... }: {
    nixosConfigurations.yourhostname = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./configuration.nix
        dotfiles.nixosModules.default
        {
          programs.zsh-dotfiles = {
            enable = true;
            users.yourusername = {
              enable = true;
              # useDeclarative = true;  # Default when dotfiles input is available

              # Optional: NixOS-specific configuration
              extraConfig = ''
                # Machine-specific paths
                export WORK_DIR="/mnt/work"

                # NixOS-specific aliases
                alias rebuild='sudo nixos-rebuild switch --flake /etc/nixos'
                alias nixedit='nvim /etc/nixos/configuration.nix'

                # Override dotfiles settings for this machine
                export EDITOR="code --wait"
              '';
            };
          };
        }
      ];
    };
  };
}
```

2. Enable flakes (if not already enabled):
```nix
# In configuration.nix
nix.settings.experimental-features = [ "nix-command" "flakes" ];
```

3. Rebuild NixOS:
```bash
sudo nixos-rebuild switch --flake /etc/nixos
```

4. Done! Your shell is configured. Dotfiles were fetched from GitHub automatically.

#### Updating Dotfiles

```bash
# Update to latest version
cd /etc/nixos
nix flake update dotfiles
sudo nixos-rebuild switch --flake .

# Or update all inputs
nix flake update
sudo nixos-rebuild switch --flake .
```

This is equivalent to `git pull` on traditional systems.

### Mode 2: Local Clone (Compatible with Traditional Linux)

Use when you want to edit dotfiles locally or need compatibility with non-NixOS systems.

#### Installation

1. Clone dotfiles:
```bash
git clone https://github.com/yourusername/dotfiles ~/.dotfiles
```

2. Add to `/etc/nixos/flake.nix`:
```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    dotfiles.url = "path:/home/yourusername/.dotfiles";
  };

  outputs = { self, nixpkgs, dotfiles, ... }: {
    nixosConfigurations.yourhostname = nixpkgs.lib.nixosSystem {
      modules = [
        ./configuration.nix
        dotfiles.nixosModules.default
        {
          programs.zsh-dotfiles = {
            enable = true;
            users.yourusername = {
              enable = true;
              useDeclarative = false;  # Use local clone
              dotfilesPath = "/home/yourusername/.dotfiles";
            };
          };
        }
      ];
    };
  };
}
```

3. Rebuild:
```bash
sudo nixos-rebuild switch --flake /etc/nixos
```

#### Updating Dotfiles

```bash
cd ~/.dotfiles
git pull
exec zsh  # Reload shell
```

### Configuration Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enable` | bool | false | Enable dotfiles for this user |
| `useDeclarative` | bool | auto | Use Nix store mode (true) or local clone (false). Auto-detects based on flake input. |
| `dotfilesPath` | string | `~/.dotfiles` | Path to local clone (local mode only) |
| `extraConfig` | lines | "" | NixOS-specific zsh config (loaded after dotfiles, before ~/.zshrc.local) |

### Configuration Layers

When using declarative mode, configuration is loaded in this order:

1. **Dotfiles** (from Nix store, immutable) - Generic shell config
2. **extraConfig** (from NixOS config, declarative) - Machine-specific settings
3. **~/.zshrc.local** (user-writable, not in git) - Quick overrides/secrets

Example of where settings belong:

| Setting | Goes In | Why |
|---------|---------|-----|
| `alias ll='ls -la'` | Dotfiles repo | Universal alias |
| `export EDITOR="nvim"` | Dotfiles repo | Your default preference |
| `alias rebuild='nixos-rebuild...'` | extraConfig | NixOS-specific |
| Work-specific paths | extraConfig | Machine-specific but declarative |
| `export API_KEY="..."` | ~/.zshrc.local | Secret, not in git |

### Package Management

On NixOS, packages and plugins are managed declaratively:
- **Packages**: zsh, fzf, zoxide, fd, git installed via Nix
- **Plugins**: fzf-tab, autosuggestions, syntax-highlighting from nixpkgs (no git clones)
- **Core config**: Your `core/*.zsh` files (from Nix store or local clone)
- **Updates**: `nix flake update` (declarative) or `git pull` (local)

### Comparison Table

| Aspect | Traditional Linux | NixOS Declarative | NixOS Local Clone |
|--------|------------------|-------------------|-------------------|
| Package install | `apt/apk/pacman` | Declarative in flake | Declarative in flake |
| Plugin install | Git clone to `~/.zsh/` | Via nixpkgs | Via nixpkgs |
| Dotfiles location | `~/.dotfiles` (git) | Nix store (immutable) | `~/.dotfiles` (git) |
| Update command | `git pull` | `nix flake update` | `git pull` |
| Fresh system setup | Clone + install.sh | Just rebuild | Clone + rebuild |
| Live editing | Yes | No (need rebuild) | Yes |
| Reproducibility | Manual | Full | Partial |

### Troubleshooting

**Plugins not loading:**
```bash
# Verify configuration
programs.zsh-dotfiles.enable = true
programs.zsh-dotfiles.users.yourusername.enable = true

# Rebuild
sudo nixos-rebuild switch --flake /etc/nixos
```

**~/.zshrc already exists:**
```bash
mv ~/.zshrc ~/.zshrc.backup
sudo nixos-rebuild switch --flake /etc/nixos
```

**Want to test changes before pushing (declarative mode):**
```nix
# Temporarily use local path in flake.nix
dotfiles.url = "path:/home/yourusername/dotfiles-dev";
```

**extraConfig not taking effect:**
```bash
# Rebuild to regenerate ~/.zshrc
sudo nixos-rebuild switch --flake /etc/nixos
exec zsh
```
