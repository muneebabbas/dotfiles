# Zsh history configuration

# History size
HISTSIZE=5000
SAVEHIST=10000
HISTFILE=~/.zsh_history

# Share history across all sessions
setopt SHARE_HISTORY

# Append to history when command finishes (avoids race with parallel sessions)
setopt INC_APPEND_HISTORY_TIME

# Don't record duplicate commands
setopt HIST_IGNORE_DUPS

# Don't record commands starting with space
setopt HIST_IGNORE_SPACE

# Remove older duplicate entries from history
setopt HIST_EXPIRE_DUPS_FIRST

# Don't display duplicates when searching
setopt HIST_FIND_NO_DUPS

# Record timestamp for each command
setopt EXTENDED_HISTORY

# Ignore common commands
HISTORY_IGNORE='(ls|ll|la|cd|pwd|bg|fg|history|clear)'
