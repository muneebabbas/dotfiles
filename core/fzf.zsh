# FZF and Zoxide integration for zsh
# Gracefully handles missing dependencies

# FZF configuration
if command -v fzf &>/dev/null; then
    # Set FZF default options
    export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'

    # Use fd if available for file listing
    if command -v fd &>/dev/null; then
        export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
        export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    fi

    # Source FZF key bindings if available
    if [[ -f /usr/share/doc/fzf/examples/key-bindings.zsh ]]; then
        source /usr/share/doc/fzf/examples/key-bindings.zsh
    elif [[ -f /usr/share/fzf/key-bindings.zsh ]]; then
        source /usr/share/fzf/key-bindings.zsh
    elif [[ -f ~/.fzf/shell/key-bindings.zsh ]]; then
        source ~/.fzf/shell/key-bindings.zsh
    fi

    # Source FZF completion if available
    if [[ -f /usr/share/doc/fzf/examples/completion.zsh ]]; then
        source /usr/share/doc/fzf/examples/completion.zsh
    elif [[ -f /usr/share/fzf/completion.zsh ]]; then
        source /usr/share/fzf/completion.zsh
    elif [[ -f ~/.fzf/shell/completion.zsh ]]; then
        source ~/.fzf/shell/completion.zsh
    fi
fi

# Zoxide with caching (avoids subprocess on every shell start)
if command -v zoxide &>/dev/null; then
    _zoxide_cache="${XDG_CACHE_HOME:-$HOME/.cache}/zoxide-init.zsh"
    if [[ ! -f "$_zoxide_cache" ]] || [[ "$(command -v zoxide)" -nt "$_zoxide_cache" ]]; then
        mkdir -p "${_zoxide_cache:h}"
        zoxide init zsh > "$_zoxide_cache"
    fi
    source "$_zoxide_cache"
    unset _zoxide_cache
fi
