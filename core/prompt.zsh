# Zsh git-aware prompt
# Two-line prompt with git integration

# Enable prompt substitution
setopt PROMPT_SUBST

# Load datetime module for EPOCHSECONDS (command timing)
zmodload zsh/datetime 2>/dev/null

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

# Capture command start time
__prompt_preexec() {
    __prompt_cmd_start=$EPOCHREALTIME
}

# Calculate elapsed time after command execution
__prompt_precmd() {
    if [[ -n $__prompt_cmd_start ]]; then
        __prompt_cmd_elapsed=$((EPOCHREALTIME - __prompt_cmd_start))
        unset __prompt_cmd_start
    else
        __prompt_cmd_elapsed=0
    fi
}

# Build right-side prompt
__build_rprompt() {
    # Colors
    local reset='%f%b'
    local cyan='%F{cyan}'
    local gray='%F{240}'

    local rprompt_parts=()

    # Execution time (only if >= threshold, default 1 second)
    local threshold="${CMD_TIME_THRESHOLD:-1}"
    if [[ ${SHOW_CMD_TIME:-1} -eq 1 ]] && [[ ${__prompt_cmd_elapsed:-0} -ge $threshold ]]; then
        local elapsed=${__prompt_cmd_elapsed}
        if [[ $elapsed -ge 60 ]]; then
            # For times >= 60s, show as "1m30s" (no decimals)
            local mins=$((${elapsed%.*} / 60))
            local secs=$((${elapsed%.*} % 60))
            rprompt_parts+=("${gray}${mins}m${secs}s${reset}")
        else
            # For times < 60s, show with 1 decimal place "2.5s"
            local formatted_time=$(printf "%.1f" $elapsed)
            rprompt_parts+=("${gray}${formatted_time}s${reset}")
        fi
    fi

    # Current time (HH:MM format)
    if [[ ${SHOW_CLOCK:-1} -eq 1 ]]; then
        rprompt_parts+=("${cyan}%T${reset}")
    fi

    # Join parts with double space separator
    RPROMPT="${(j:  :)rprompt_parts}"
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
    RPROMPT=""  # Clear right prompt in transient mode
}

# ZLE widget to handle transient prompt on line finish
__prompt_line_finish() {
    # Set to transient prompt when line is finished
    __prompt_transient
    zle reset-prompt
}

# Set up ZLE widget for line finish (cleaner than overriding accept-line)
zle -N zle-line-finish __prompt_line_finish

# Set precmd and preexec hooks
autoload -Uz add-zsh-hook
add-zsh-hook preexec __prompt_preexec    # Track command start time
add-zsh-hook precmd __prompt_precmd      # Calculate elapsed time
add-zsh-hook precmd __build_prompt       # Build left prompt
add-zsh-hook precmd __build_rprompt      # Build right prompt
