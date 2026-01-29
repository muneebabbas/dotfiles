#!/usr/bin/env bash
# Install core tools (zsh, fzf, zoxide, and zsh plugins)
# OS-aware installation script

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source OS detection
source "$SCRIPT_DIR/detect-os.sh"

# Print colored message
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

# Determine sudo command prefix
setup_sudo() {
    # If already root, no sudo needed
    if [ "$EUID" -eq 0 ]; then
        SUDO=""
        print_info "Running as root"
        return 0
    fi

    # Check if sudo exists
    if command -v sudo &> /dev/null; then
        SUDO="sudo"
        print_info "Will use sudo for package installation"
        # Test sudo access
        if ! sudo -v &> /dev/null; then
            print_warning "sudo requires password - you may be prompted"
        fi
    else
        SUDO=""
        print_warning "sudo not found - attempting without privileges"
        print_warning "Package installation may fail if not running as root"
    fi
}

# Install Zsh
install_zsh() {
    if command -v zsh &> /dev/null; then
        print_success "zsh is already installed"
        return 0
    fi

    local os=$(detect_os)
    print_info "Installing zsh on $os..."

    case "$os" in
        debian|ubuntu)
            $SUDO apt-get update
            $SUDO apt-get install -y zsh
            ;;
        alpine)
            $SUDO apk add --no-cache zsh
            ;;
        arch)
            $SUDO pacman -Sy --noconfirm zsh
            ;;
        *)
            print_error "Unknown OS, cannot install zsh"
            return 1
            ;;
    esac

    if command -v zsh &> /dev/null; then
        print_success "zsh installed successfully"
    else
        print_error "Failed to install zsh"
        return 1
    fi
}

# Install Zsh plugins
install_zsh_plugins() {
    print_info "Installing zsh plugins..."

    local plugin_dir="$HOME/.zsh"
    mkdir -p "$plugin_dir"

    # Install zsh-autosuggestions
    if [ ! -d "$plugin_dir/zsh-autosuggestions" ]; then
        print_info "Installing zsh-autosuggestions..."
        git clone --depth 1 https://github.com/zsh-users/zsh-autosuggestions "$plugin_dir/zsh-autosuggestions"
        print_success "zsh-autosuggestions installed"
    else
        print_success "zsh-autosuggestions already installed"
    fi

    # Install zsh-syntax-highlighting
    if [ ! -d "$plugin_dir/zsh-syntax-highlighting" ]; then
        print_info "Installing zsh-syntax-highlighting..."
        git clone --depth 1 https://github.com/zsh-users/zsh-syntax-highlighting "$plugin_dir/zsh-syntax-highlighting"
        print_success "zsh-syntax-highlighting installed"
    else
        print_success "zsh-syntax-highlighting already installed"
    fi
}

# Install FZF
install_fzf() {
    if command -v fzf &> /dev/null; then
        print_success "fzf is already installed"
        return 0
    fi

    local os=$(detect_os)
    print_info "Installing fzf on $os..."

    case "$os" in
        debian|ubuntu)
            $SUDO apt-get update
            $SUDO apt-get install -y fzf
            ;;
        alpine)
            $SUDO apk add --no-cache fzf
            ;;
        arch)
            $SUDO pacman -Sy --noconfirm fzf
            ;;
        *)
            print_warning "Unknown OS, attempting git installation..."
            install_fzf_git
            ;;
    esac

    if command -v fzf &> /dev/null; then
        print_success "fzf installed successfully"
    else
        print_error "Failed to install fzf"
        return 1
    fi
}

# Install FZF from git (fallback method)
install_fzf_git() {
    local install_dir="$HOME/.fzf"

    if [ -d "$install_dir" ]; then
        print_warning "~/.fzf directory already exists, skipping git install"
        return 1
    fi

    print_info "Installing fzf from GitHub..."
    git clone --depth 1 https://github.com/junegunn/fzf.git "$install_dir"
    "$install_dir/install" --all --no-update-rc
}

# Install Zoxide
install_zoxide() {
    if command -v zoxide &> /dev/null; then
        print_success "zoxide is already installed"
        return 0
    fi

    local os=$(detect_os)
    print_info "Installing zoxide on $os..."

    case "$os" in
        debian|ubuntu)
            # Zoxide might not be in default repos for older versions
            if apt-cache show zoxide &> /dev/null; then
                $SUDO apt-get update
                $SUDO apt-get install -y zoxide
            else
                print_warning "zoxide not in apt repos, using install script..."
                install_zoxide_script
            fi
            ;;
        alpine)
            $SUDO apk add --no-cache zoxide
            ;;
        arch)
            $SUDO pacman -Sy --noconfirm zoxide
            ;;
        *)
            print_warning "Unknown OS, using install script..."
            install_zoxide_script
            ;;
    esac

    if command -v zoxide &> /dev/null; then
        print_success "zoxide installed successfully"
    else
        print_error "Failed to install zoxide"
        return 1
    fi
}

# Install Zoxide using official installer
install_zoxide_script() {
    print_info "Installing zoxide from official installer..."
    curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash

    # Add to PATH if not already there
    if [ -d "$HOME/.local/bin" ] && [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
        export PATH="$HOME/.local/bin:$PATH"
    fi
}

# Main installation
main() {
    print_info "Starting core tools installation"
    print_info "Detected OS: $(detect_os)"
    echo

    # Setup sudo (determine if we need it and if it's available)
    setup_sudo
    echo

    # Install tools
    install_zsh
    echo
    install_fzf
    echo
    install_zoxide
    echo
    install_zsh_plugins
    echo

    print_success "Core tools installation complete!"
    print_info "Change your shell: chsh -s \$(which zsh)"
    print_info "Then restart your shell: exec zsh"
}

main "$@"
