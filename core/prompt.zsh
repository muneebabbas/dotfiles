# Zsh git-aware prompt
# Two-line prompt with git integration

# Enable prompt substitution
setopt PROMPT_SUBST

# Function to get git branch
__git_branch() {
    local branch
    if git rev-parse --git-dir > /dev/null 2>&1; then
        branch=$(git symbolic-ref --short HEAD 2>/dev/null || git describe --tags --exact-match 2>/dev/null || echo "detached")
        echo "$branch"
    fi
}

# Function to get git status indicator
__git_status() {
    local status=""

    # Check if we're in a git repo
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        return
    fi

    # Check for uncommitted changes
    if ! git diff --quiet 2>/dev/null; then
        status="*"
    fi

    # Check for staged changes
    if ! git diff --cached --quiet 2>/dev/null; then
        status="${status}+"
    fi

    echo "$status"
}

# Function to truncate directory path
__truncate_path() {
    local path="$PWD"
    local home="$HOME"

    # Replace home with ~
    path="${path/#$home/~}"

    # If path has more than 2 levels, truncate
    local -a parts
    parts=("${(@s:/:)path}")
    local count=${#parts[@]}

    if [ $count -gt 3 ]; then
        # Show first part (~ or /) and last 2 parts
        if [ "${parts[1]}" = "~" ]; then
            echo "~/${parts[-2]}/${parts[-1]}"
        else
            echo "/${parts[-2]}/${parts[-1]}"
        fi
    else
        echo "$path"
    fi
}

# Build the prompt
__build_prompt() {
    local exit_code=$?

    # Colors
    local reset='%f%b'
    local cyan='%F{cyan}'
    local blue='%F{blue}'
    local green='%F{green}'
    local yellow='%F{yellow}'
    local red='%F{red}'
    local gray='%F{240}'

    # User@hostname
    local user_host="${cyan}%n@%m${reset}"

    # Current directory
    local dir="${blue}$(__truncate_path)${reset}"

    # Git branch and status
    local git_info=""
    local branch=$(__git_branch)
    if [ -n "$branch" ]; then
        local status=$(__git_status)
        if [ -n "$status" ]; then
            git_info=" ${gray}on${reset} ${yellow}${branch}${status}${reset}"
        else
            git_info=" ${gray}on${reset} ${green}${branch}${reset}"
        fi
    fi

    # Prompt character (green if success, red if failure)
    local prompt_char
    if [ $exit_code -eq 0 ]; then
        prompt_char="${green}❯${reset}"
    else
        prompt_char="${red}❯${reset}"
    fi

    # Build final two-line prompt
    # Line 1: ╭─ user@host in ~/path on branch
    # Line 2: ╰─❯
    PROMPT="${gray}╭─${reset} ${user_host} ${gray}in${reset} ${dir}${git_info}
${gray}╰─${reset}${prompt_char} "
}

# Set precmd to build prompt before each command
autoload -Uz add-zsh-hook
add-zsh-hook precmd __build_prompt
