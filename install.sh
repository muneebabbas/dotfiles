#!/usr/bin/env bash
# Dotfiles installation script
# Usage: ./install.sh [--core-tools]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Get script directory
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Parse command line arguments
INSTALL_CORE_TOOLS=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --core-tools)
            INSTALL_CORE_TOOLS=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --core-tools    Install zsh, fzf, zoxide, and plugins"
            echo "  -h, --help      Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Print colored messages
print_header() {
    echo -e "\n${CYAN}=== $1 ===${NC}\n"
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Migrate existing .zshrc to local config
migrate_existing_zshrc() {
    print_header "Checking for existing .zshrc"

    # Skip if already symlinked to our config
    if is_zshrc_installed; then
        print_info "Already using dotfiles, skipping migration"
        return 0
    fi

    # Skip if it's our generated config (from older install)
    if [ -f "$HOME/.zshrc" ] && grep -q "~/.dotfiles/core/zshrc" "$HOME/.zshrc"; then
        print_info "Already using dotfiles, skipping migration"
        return 0
    fi

    if [ -f "$HOME/.zshrc" ]; then
        # Backup to /tmp first
        "$DOTFILES_DIR/scripts/backup.sh"

        # Migrate to local/zshrc_local
        local local_config="$DOTFILES_DIR/local/zshrc_local"

        if [ -f "$local_config" ]; then
            # Append to existing local config
            echo "" >> "$local_config"
            echo "# === Migrated from existing ~/.zshrc ===" >> "$local_config"
            cat "$HOME/.zshrc" >> "$local_config"
            print_success "Appended existing .zshrc to local/zshrc_local"
        else
            # Create new local config from existing .zshrc
            echo "# Machine-specific zsh configuration" > "$local_config"
            echo "# Migrated from existing ~/.zshrc" >> "$local_config"
            echo "" >> "$local_config"
            cat "$HOME/.zshrc" >> "$local_config"
            print_success "Migrated existing .zshrc to local/zshrc_local"
        fi

        echo ""
        print_warning "Please review ~/.dotfiles/local/zshrc_local"
        print_warning "Remove any settings that conflict with core dotfiles:"
        print_warning "  - Prompt configuration (PS1, PROMPT)"
        print_warning "  - History settings (HISTSIZE, HISTFILE, etc.)"
        print_warning "  - Keybindings that may conflict"
        echo ""
        read -p "Press Enter to continue after reviewing, or Ctrl+C to abort..."
    else
        print_info "No existing .zshrc found"
    fi
}

# Create local config directory
setup_local_config() {
    print_header "Setting up local configuration"

    if [ ! -f "$DOTFILES_DIR/local/zshrc_local" ]; then
        cp "$DOTFILES_DIR/local/zshrc_local.example" "$DOTFILES_DIR/local/zshrc_local"
        print_success "Created local configuration file"
        print_info "Edit ~/.dotfiles/local/zshrc_local for machine-specific settings"
    else
        print_info "Local configuration already exists"
    fi
}

# Check if zshrc is already correctly symlinked
is_zshrc_installed() {
    [ -L "$HOME/.zshrc" ] && [ "$(readlink "$HOME/.zshrc")" = "$DOTFILES_DIR/core/zshrc" ]
}

# Install main .zshrc as symlink
install_zshrc() {
    print_header "Installing .zshrc"

    if is_zshrc_installed; then
        print_info "~/.zshrc already symlinked correctly"
        return 0
    fi

    # Remove existing file/symlink if present (already backed up in migrate step)
    if [ -e "$HOME/.zshrc" ] || [ -L "$HOME/.zshrc" ]; then
        rm "$HOME/.zshrc"
    fi

    ln -s "$DOTFILES_DIR/core/zshrc" "$HOME/.zshrc"
    print_success "Symlinked ~/.zshrc -> $DOTFILES_DIR/core/zshrc"
}

# Install core tools
install_core_tools() {
    print_header "Installing core tools"

    print_info "Running core tools installation..."
    echo

    if [ -f "$DOTFILES_DIR/scripts/setup-core.sh" ]; then
        bash "$DOTFILES_DIR/scripts/setup-core.sh"
    else
        print_error "setup-core.sh not found"
    fi
}


# Make scripts executable
make_scripts_executable() {
    print_header "Setting up scripts"

    chmod +x "$DOTFILES_DIR/scripts/"*.sh
    print_success "Made all scripts executable"
}

# Print next steps
print_next_steps() {
    print_header "Installation Complete!"

    echo -e "${GREEN}Your dotfiles are now installed!${NC}\n"
    echo "Next steps:"
    echo ""
    echo "  1. Change to zsh (if not already):"
    echo -e "     ${CYAN}chsh -s \$(which zsh)${NC}"
    echo ""
    echo "  2. Reload your shell:"
    echo -e "     ${CYAN}exec zsh${NC}"
    echo ""
    echo "  3. Customize for this machine:"
    echo -e "     ${CYAN}vim ~/.dotfiles/local/zshrc_local${NC}"
    echo ""

    if [ "$INSTALL_CORE_TOOLS" = false ]; then
        echo "  3. Install core tools (optional):"
        echo -e "     ${CYAN}bash ~/.dotfiles/scripts/setup-core.sh${NC}"
        echo ""
    fi

    echo "Features enabled:"
    echo "  • Git-aware prompt with branch and status"
    echo "  • Enhanced history with timestamps"
    echo "  • Useful aliases (ll, la, ..., etc.)"

    if [ "$INSTALL_CORE_TOOLS" = true ]; then
        echo "  • Zsh with plugins (fzf-tab, autosuggestions, syntax highlighting)"
        echo "  • FZF fuzzy finder (Ctrl+R, Ctrl+T, Alt+C)"
        echo "  • Zoxide smart directory jumping"
    fi

    echo ""
    echo -e "${BLUE}Configuration location:${NC} $DOTFILES_DIR"
    echo ""
}

# Main installation flow
main() {
    clear
    echo -e "${CYAN}"
    echo "╔═══════════════════════════════════════╗"
    echo "║     Dotfiles Installation Script      ║"
    echo "╚═══════════════════════════════════════╝"
    echo -e "${NC}"

    print_info "Installation directory: $DOTFILES_DIR"
    echo

    # Detect NixOS and provide guidance
    if [ -f /etc/os-release ] && grep -q "^ID=nixos" /etc/os-release; then
        print_warning "NixOS detected!"
        print_info "Recommended: Use the Nix flake for declarative configuration"
        print_info "See CLAUDE.md for NixOS setup instructions"
        print_info "Alternative: Continue with this script for traditional symlink setup"
        echo
        read -p "Continue with traditional install? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Exiting. See CLAUDE.md for NixOS flake instructions."
            exit 0
        fi
        echo
    fi

    # All steps are idempotent - safe to run multiple times
    make_scripts_executable
    migrate_existing_zshrc
    setup_local_config
    install_zshrc

    if [ "$INSTALL_CORE_TOOLS" = true ]; then
        install_core_tools
    fi

    print_next_steps
}

main "$@"
