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
