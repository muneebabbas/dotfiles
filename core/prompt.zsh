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
    local git_status=""

    # Check if we're in a git repo
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        return
    fi

    # Check for any changes (working or staged)
    if ! git diff --quiet 2>/dev/null || ! git diff --cached --quiet 2>/dev/null; then
        git_status="*"
    fi

    echo "$git_status"
}

# Function to get remote tracking status
__git_remote_status() {
    local remote_status=""

    # Check if we're in a git repo
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        return
    fi

    # Get ahead/behind counts
    local ahead behind
    ahead=$(git rev-list --count @{upstream}..HEAD 2>/dev/null)
    behind=$(git rev-list --count HEAD..@{upstream} 2>/dev/null)

    # Add indicators
    if [ -n "$ahead" ] && [ "$ahead" -gt 0 ]; then
        remote_status="${remote_status}⇡"
    fi

    if [ -n "$behind" ] && [ "$behind" -gt 0 ]; then
        remote_status="${remote_status}⇣"
    fi

    echo "$remote_status"
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
        local git_status=$(__git_status)
        local remote_status=$(__git_remote_status)

        # Determine branch color (yellow if dirty, green if clean)
        local branch_color
        if [ -n "$git_status" ]; then
            branch_color="${yellow}"
        else
            branch_color="${green}"
        fi

        # Build git info: branch* ⇡⇣
        git_info=" ${gray}on${reset} ${branch_color}${branch}${git_status}${reset}"

        # Add remote status with spacing if present
        if [ -n "$remote_status" ]; then
            git_info="${git_info} ${cyan}${remote_status}${reset}"
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

# Track if this is the first prompt
typeset -g __prompt_first_run=1

# Add spacing between prompts (but not on first prompt)
__add_prompt_spacing() {
    if [ $__prompt_first_run -eq 0 ]; then
        echo
    fi
    __prompt_first_run=0
}

# Set precmd hooks
autoload -Uz add-zsh-hook
add-zsh-hook precmd __add_prompt_spacing
add-zsh-hook precmd __build_prompt
