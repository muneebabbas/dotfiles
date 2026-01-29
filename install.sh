#!/usr/bin/env bash
# Dotfiles installation script
# Usage: ./install.sh [--core-tools] [--full]

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
ENABLE_FULL=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --core-tools)
            INSTALL_CORE_TOOLS=true
            shift
            ;;
        --full)
            ENABLE_FULL=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --core-tools    Install zsh, fzf, zoxide, and plugins"
            echo "  --full          Enable full feature set"
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

# Backup existing dotfiles
backup_dotfiles() {
    print_header "Backing up existing dotfiles"

    # Check if .zshrc already sources dotfiles (don't backup our own config)
    if [ -f "$HOME/.zshrc" ] && grep -q "~/.dotfiles/core/zshrc" "$HOME/.zshrc"; then
        print_info "Already using dotfiles, skipping backup"
        return 0
    fi

    if [ -f "$HOME/.zshrc" ]; then
        "$DOTFILES_DIR/scripts/backup.sh"
    else
        print_info "No existing .zshrc found, skipping backup"
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

# Install main .zshrc
install_zshrc() {
    print_header "Installing .zshrc"

    local zshrc_content='# Source dotfiles core config
if [ -f ~/.dotfiles/core/zshrc ]; then
    source ~/.dotfiles/core/zshrc
fi

# Source machine-specific overrides
if [ -f ~/.dotfiles/local/zshrc_local ]; then
    source ~/.dotfiles/local/zshrc_local
fi'

    # Always write .zshrc to ensure latest version
    echo "$zshrc_content" > "$HOME/.zshrc"
    print_success "Installed .zshrc"
    print_info "Shell now sources from ~/.dotfiles/core/zshrc"
}

# Install core tools
install_core_tools() {
    print_header "Installing core tools"

    if [ "$INSTALL_CORE_TOOLS" = true ]; then
        print_info "Running core tools installation..."
        echo

        if [ -f "$DOTFILES_DIR/scripts/setup-core.sh" ]; then
            bash "$DOTFILES_DIR/scripts/setup-core.sh"
        else
            print_error "setup-core.sh not found"
        fi
    else
        print_info "Skipping core tools installation"
        print_info "To install zsh, fzf, zoxide, and plugins later, run:"
        print_info "  bash ~/.dotfiles/scripts/setup-core.sh"
    fi
}

# Enable full features
enable_full_features() {
    if [ "$ENABLE_FULL" = true ]; then
        print_header "Enabling full features"
        print_success "Full features are enabled"
        print_info "Edit ~/.dotfiles/full/zshrc_full to add custom features"
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

    # Run installation steps
    make_scripts_executable
    backup_dotfiles
    setup_local_config
    install_zshrc
    enable_full_features
    install_core_tools

    # Show next steps
    print_next_steps
}

main "$@"
