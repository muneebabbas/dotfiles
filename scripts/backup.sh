#!/usr/bin/env bash
# Backup existing dotfiles before installation

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Create backup directory in /tmp (auto-cleaned on reboot)
BACKUP_DIR="/tmp/dotfiles_backup_$(date +%Y%m%d_%H%M%S)"

backup_file() {
    local file="$1"

    if [ -f "$file" ] || [ -L "$file" ]; then
        if [ ! -d "$BACKUP_DIR" ]; then
            mkdir -p "$BACKUP_DIR"
            print_info "Created backup directory: $BACKUP_DIR"
        fi

        cp -P "$file" "$BACKUP_DIR/"
        print_success "Backed up: $file"
        return 0
    fi

    return 1
}

# Main backup function
main() {
    print_info "Starting dotfiles backup..."

    local files_backed_up=0

    # Backup .zshrc
    if backup_file "$HOME/.zshrc"; then
        files_backed_up=$((files_backed_up + 1))
    fi

    # Backup .zshenv if exists
    if backup_file "$HOME/.zshenv"; then
        files_backed_up=$((files_backed_up + 1))
    fi

    if [ $files_backed_up -eq 0 ]; then
        print_info "No existing dotfiles found to backup"
    else
        echo
        print_success "Backed up $files_backed_up file(s) to: $BACKUP_DIR"
    fi

    return 0
}

main "$@"
