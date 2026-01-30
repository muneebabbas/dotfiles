# Zsh keybindings and completion configuration

# Use emacs-style keybindings
bindkey -e

# Cached compinit - only rebuild dump if older than 24 hours
autoload -Uz compinit
if [[ -n ~/.zcompdump(#qN.mh+24) ]]; then
    compinit
else
    compinit -C
fi

# Case-insensitive completion
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

# Colored completion (files, directories, etc)
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# Menu behavior: disable for fzf-tab, else use native menu
if [[ -d ~/.zsh/fzf-tab ]]; then
    zstyle ':completion:*' menu no
    zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
    zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'
else
    zstyle ':completion:*' menu select
fi

setopt AUTO_MENU
setopt AUTO_LIST
setopt MARK_DIRS

# Up/down arrow search through history based on what you've typed
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey "^[[A" up-line-or-beginning-search
bindkey "^[[B" down-line-or-beginning-search

# Ctrl+Left/Right to move by word
bindkey "^[[1;5D" backward-word
bindkey "^[[1;5C" forward-word
