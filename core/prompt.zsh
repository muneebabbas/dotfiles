# Zsh git-aware prompt
# Two-line prompt with git integration

# Enable prompt substitution
setopt PROMPT_SUBST

# Optimized git info - single command instead of 8+
__git_prompt_info() {
    local git_output
    git_output=$(GIT_OPTIONAL_LOCKS=0 git status --porcelain=v2 --branch 2>/dev/null) || return

    local branch="" ahead=0 behind=0 dirty=""
    local line

    # Pure zsh parsing - no grep/cut subprocesses
    while IFS= read -r line; do
        case "$line" in
            "# branch.head "*)
                branch="${line#\# branch.head }"
                [[ "$branch" == "(detached)" ]] && branch="detached"
                ;;
            "# branch.ab "*)
                local ab="${line#\# branch.ab }"
                ahead="${ab%% *}"; ahead="${ahead#+}"
                behind="${ab##* }"; behind="${behind#-}"
                ;;
            [^#]*)
                dirty="*"
                ;;
        esac
    done <<< "$git_output"

    [[ -z "$branch" ]] && return

    local remote_status=""
    [[ $ahead -gt 0 ]] && remote_status+="⇡"
    [[ $behind -gt 0 ]] && remote_status+="⇣"

    echo "${branch}|${dirty}|${remote_status}"
}

# Function to truncate directory path
# Set TRUNCATE_PROMPT=1 in local/zshrc_local to enable truncation
__truncate_path() {
    local path="$PWD"
    local home="$HOME"

    # Replace home with ~
    path="${path/#$home/~}"

    # If truncation disabled (default), return full path
    if [[ "${TRUNCATE_PROMPT:-0}" != "1" ]]; then
        echo "$path"
        return
    fi

    # If path has more than 2 levels, truncate
    local -a parts
    parts=("${(@s:/:)path}")
    local count=${#parts[@]}

    if [ $count -gt 3 ]; then
        # Show first part (~ or /) and last 2 parts with …/ to indicate truncation
        if [ "${parts[1]}" = "~" ]; then
            echo "~/…/${parts[-2]}/${parts[-1]}"
        else
            echo "/…/${parts[-2]}/${parts[-1]}"
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

    # Git branch and status (single git command)
    local git_info=""
    local git_data=$(__git_prompt_info)
    if [[ -n "$git_data" ]]; then
        # Parse with fallback for malformed output
        local branch dirty remote_status
        IFS='|' read -r branch dirty remote_status <<< "${git_data:-||}"
        [[ -z "$branch" ]] && branch=""

        # Determine branch color (yellow if dirty, green if clean)
        local branch_color
        if [[ -n "$dirty" ]]; then
            branch_color="${yellow}"
        else
            branch_color="${green}"
        fi

        # Build git info: branch* ⇡⇣
        git_info=" ${gray}on${reset} ${branch_color}${branch}${dirty}${reset}"

        # Add remote status with spacing if present
        if [[ -n "$remote_status" ]]; then
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

    # Build final two-line prompt with newline before it
    # Blank line for spacing
    # Line 1: ╭─ user@host in ~/path on branch
    # Line 2: ╰─❯
    PROMPT="
${gray}╭─${reset} ${user_host} ${gray}in${reset} ${dir}${git_info}
${gray}╰─${reset}${prompt_char} "
}

# Transient prompt support
# This makes old prompts collapse to just ❯ after execution

# Function to set transient (simplified) prompt
__prompt_transient() {
    local exit_code=$?

    # Colors
    local reset='%f%b'
    local green='%F{green}'
    local red='%F{red}'

    # Prompt character based on exit code
    local prompt_char
    if [ $exit_code -eq 0 ]; then
        prompt_char="${green}❯${reset}"
    else
        prompt_char="${red}❯${reset}"
    fi

    PROMPT="${prompt_char} "
}

# ZLE widget to handle transient prompt on line finish
__prompt_line_finish() {
    # Set to transient prompt when line is finished
    __prompt_transient
    zle reset-prompt
}

# Set up ZLE widget for line finish (cleaner than overriding accept-line)
zle -N zle-line-finish __prompt_line_finish

# Set precmd hooks
autoload -Uz add-zsh-hook
add-zsh-hook precmd __build_prompt
