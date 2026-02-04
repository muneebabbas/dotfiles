#!/usr/bin/env zsh
# Prompt performance benchmark script
# Usage: ./scripts/benchmark-prompt.sh [samples]

# Number of samples (default 100)
SAMPLES=${1:-100}

# Get script directory and repo root
SCRIPT_DIR="${0:A:h}"
REPO_ROOT="${SCRIPT_DIR:h}"

# Colors for output
RESET='\033[0m'
BOLD='\033[1m'
CYAN='\033[36m'
GRAY='\033[90m'

# Benchmark a function
# Args: function_name, samples
benchmark_function() {
    local func_name=$1
    local samples=$2
    local -a times
    local start end elapsed

    for ((i=1; i<=samples; i++)); do
        start=$(($(date +%s%N) / 1000000))  # milliseconds
        eval "$func_name" > /dev/null 2>&1
        end=$(($(date +%s%N) / 1000000))
        elapsed=$((end - start))
        times+=($elapsed)
    done

    # Calculate statistics
    local sum=0
    local min=999999
    local max=0

    for time in "${times[@]}"; do
        sum=$((sum + time))
        [[ $time -lt $min ]] && min=$time
        [[ $time -gt $max ]] && max=$time
    done

    local avg=$((sum / samples))

    # Calculate standard deviation (using zsh float arithmetic)
    local variance_sum=0
    for time in "${times[@]}"; do
        local diff=$((time - avg))
        variance_sum=$((variance_sum + diff * diff))
    done
    local variance=$((variance_sum / samples))
    # Simple integer square root approximation
    local stddev=0
    if [[ $variance -gt 0 ]]; then
        stddev=$(( $(echo "sqrt($variance)" | awk '{print int($1+0.5)}') ))
    fi

    # Calculate prompts per second
    local prompts_per_sec=$((samples * 1000 / sum))

    echo "$avg|$min|$max|$stddev|$prompts_per_sec"
}

# Format time output
format_time() {
    local avg=$1
    local min=$2
    local max=$3
    printf "avg=%-5.1fms  min=%-5.1fms  max=%-5.1fms" "$avg" "$min" "$max"
}

# Print section header
print_header() {
    echo "${BOLD}${CYAN}$1${RESET}"
}

# Print box with results
print_box() {
    local title=$1
    local -a lines=("${(@f)2}")

    # Box drawing characters
    local tl="┌" tr="┐" bl="└" br="┘"
    local h="─" v="│"

    # Calculate width
    local width=60

    # Top border
    echo -n "$tl"
    for ((i=1; i<=width; i++)); do echo -n "$h"; done
    echo "$tr"

    # Title
    printf "$v %-${width}s $v\n" "$title"

    # Separator
    echo -n "├"
    for ((i=1; i<=width; i++)); do echo -n "$h"; done
    echo "┤"

    # Content lines
    for line in "${lines[@]}"; do
        printf "$v %-${width}s $v\n" "$line"
    done

    # Bottom border
    echo -n "$bl"
    for ((i=1; i<=width; i++)); do echo -n "$h"; done
    echo "$br"
    echo
}

# Source the prompt file
cd "$REPO_ROOT"
source "$REPO_ROOT/core/prompt.zsh"

# Setup environment
export TRUNCATE_PROMPT=0
setopt PROMPT_SUBST

print_header "=== Prompt Performance Benchmark ==="
echo "Samples: $SAMPLES iterations per scenario"
echo

# Scenario 1: Non-git directory
cd /tmp
mkdir -p /tmp/bench-nogit-$$
cd /tmp/bench-nogit-$$

result=$(benchmark_function "__build_prompt" $SAMPLES)
IFS='|' read -r avg min max stddev pps <<< "$result"
prompt_time=$avg

# Check if __build_rprompt exists
if typeset -f __build_rprompt > /dev/null; then
    rprompt_result=$(benchmark_function "__build_rprompt" $SAMPLES)
    IFS='|' read -r rprompt_avg rprompt_min rprompt_max rprompt_stddev rprompt_pps <<< "$rprompt_result"
    total_avg=$((avg + rprompt_avg))
    total_pps=$((total_avg > 0 ? 1000 / total_avg : 0))

    output="__build_prompt:   $(format_time $avg $min $max)
__build_rprompt:  $(format_time $rprompt_avg $rprompt_min $rprompt_max)
Total:            avg=${total_avg}.0ms  ($total_pps prompts/sec)"
else
    output="__build_prompt:   $(format_time $avg $min $max)
Total:            avg=${avg}.0ms  ($pps prompts/sec)"
fi

print_box "Non-Git Directory" "$output"

# Scenario 2: Clean git repository
cd /tmp
mkdir -p /tmp/bench-git-clean-$$
cd /tmp/bench-git-clean-$$
git init -q
git config user.email "bench@test.com"
git config user.name "Benchmark"
echo "test" > file.txt
git add . > /dev/null 2>&1
git commit -q -m "Initial commit"

git_result=$(benchmark_function "__git_prompt_info" $SAMPLES)
IFS='|' read -r git_avg git_min git_max git_stddev git_pps <<< "$git_result"

result=$(benchmark_function "__build_prompt" $SAMPLES)
IFS='|' read -r avg min max stddev pps <<< "$result"

if typeset -f __build_rprompt > /dev/null; then
    rprompt_result=$(benchmark_function "__build_rprompt" $SAMPLES)
    IFS='|' read -r rprompt_avg rprompt_min rprompt_max rprompt_stddev rprompt_pps <<< "$rprompt_result"
    total_avg=$((avg + rprompt_avg))
    total_pps=$((total_avg > 0 ? 1000 / total_avg : 0))

    output="__git_prompt_info: $(format_time $git_avg $git_min $git_max)
__build_prompt:    $(format_time $avg $min $max)
__build_rprompt:   $(format_time $rprompt_avg $rprompt_min $rprompt_max)
Total:             avg=${total_avg}.0ms  ($total_pps prompts/sec)"
else
    output="__git_prompt_info: $(format_time $git_avg $git_min $git_max)
__build_prompt:    $(format_time $avg $min $max)
Total:             avg=${avg}.0ms  ($pps prompts/sec)"
fi

print_box "Clean Git Repository" "$output"

# Scenario 3: Dirty git repository
echo "modified" >> file.txt
echo "new" > untracked.txt

git_result=$(benchmark_function "__git_prompt_info" $SAMPLES)
IFS='|' read -r git_avg git_min git_max git_stddev git_pps <<< "$git_result"

result=$(benchmark_function "__build_prompt" $SAMPLES)
IFS='|' read -r avg min max stddev pps <<< "$result"

if typeset -f __build_rprompt > /dev/null; then
    rprompt_result=$(benchmark_function "__build_rprompt" $SAMPLES)
    IFS='|' read -r rprompt_avg rprompt_min rprompt_max rprompt_stddev rprompt_pps <<< "$rprompt_result"
    total_avg=$((avg + rprompt_avg))
    total_pps=$((total_avg > 0 ? 1000 / total_avg : 0))

    output="__git_prompt_info: $(format_time $git_avg $git_min $git_max)
__build_prompt:    $(format_time $avg $min $max)
__build_rprompt:   $(format_time $rprompt_avg $rprompt_min $rprompt_max)
Total:             avg=${total_avg}.0ms  ($total_pps prompts/sec)"

    echo -e "${GRAY}Impact of RPROMPT: +${rprompt_avg}ms average (+$((rprompt_avg * 100 / avg))% overhead)${RESET}"
else
    output="__git_prompt_info: $(format_time $git_avg $git_min $git_max)
__build_prompt:    $(format_time $avg $min $max)
Total:             avg=${avg}.0ms  ($pps prompts/sec)"
fi

print_box "Dirty Git Repository" "$output"

# Cleanup
cd /tmp
rm -rf /tmp/bench-nogit-$$ /tmp/bench-git-clean-$$

echo "Benchmark complete. Lower times are better."
echo "Tip: Run with more samples for accuracy: $0 1000"
