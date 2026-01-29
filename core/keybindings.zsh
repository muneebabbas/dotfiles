# Zsh keybindings and completion configuration

# Use emacs-style keybindings
bindkey -e

# Enable completion system
autoload -Uz compinit
compinit

# Case-insensitive completion
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

# Show completion menu on ambiguous completion
setopt AUTO_MENU

# Automatically list choices on ambiguous completion
setopt AUTO_LIST

# Append / to directory symlinks
setopt MARK_DIRS

# Colored completion (files, directories, etc)
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# Enable menu selection for completion
zstyle ':completion:*' menu select

# Up/down arrow search through history based on what you've typed
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey "^[[A" up-line-or-beginning-search
bindkey "^[[B" down-line-or-beginning-search

# Ctrl+Left/Right to move by word
bindkey "^[[1;5D" backward-word
bindkey "^[[1;5C" forward-word
