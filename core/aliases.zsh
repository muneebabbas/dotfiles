# Zsh aliases

# ls aliases
alias ls='ls --color=auto'
alias ll='ls -lh'
alias la='ls -lAh'
alias l='ls -CF'

# grep with color
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# Navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'

# Safety nets
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# Convenience
alias c='clear'
alias h='history'
alias j='jobs -l'
alias path='echo -e ${PATH//:/\\n}'

# Disk usage
alias df='df -h'
alias du='du -h'
alias dud='du -d 1 -h'
alias duf='du -sh *'

# Make directory and cd into it
mkcd() {
    mkdir -p "$1" && cd "$1"
}
