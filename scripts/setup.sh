#!/usr/bin/env bash
#
# setup.sh - Script to install project dependencies and configure the environment.
#
# Installs the tools required to build and contribute to the ft_irc project:
#   - CMake (build system)
#   - GNU Make (build automation)
#   - GCC or Clang (C++98 compiler)
#   - Git (version control)
#   - Valgrind (memory leak detection)
#   - GitHub CLI (gh) - optional, required for new-work.sh/sync scripts
#
# Also activates the commit message template (.gitmessage) via:
#   git config commit.template .gitmessage
#
# Usage:
#   ./scripts/setup.sh
#
# Supported distributions: Ubuntu/Debian, Fedora/RHEL, Arch Linux, macOS (Homebrew)

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# -----------------------------------------------------------------------------
# Utility functions
# -----------------------------------------------------------------------------
log_info()  { echo -e "${BLUE}[INFO]${NC}  $*"; }
log_ok()    { echo -e "${GREEN}[OK]${NC}    $*"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }

confirm() {
    local prompt="$1"
    read -r -p "${prompt} [y/N]: " response
    case "$response" in
        [yY][eE][sS]|[yY]) return 0 ;;
        *) return 1 ;;
    esac
}

# -----------------------------------------------------------------------------
# Detect the operating system distribution
# -----------------------------------------------------------------------------
detect_distro() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            echo "$ID"
        elif [ -f /etc/redhat-release ]; then
            echo "rhel"
        else
            echo "unknown"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    else
        echo "unknown"
    fi
}

# -----------------------------------------------------------------------------
# Check if a command is available
# -----------------------------------------------------------------------------
is_installed() {
    command -v "$1" &>/dev/null
}

# -----------------------------------------------------------------------------
# Install packages on Debian/Ubuntu
# -----------------------------------------------------------------------------
install_debian() {
    log_info "Updating package lists..."
    sudo apt-get update

    log_info "Installing required packages..."
    sudo apt-get install -y \
        cmake \
        make \
        g++ \
        gcc \
        git \
        valgrind \
        gh
}

# -----------------------------------------------------------------------------
# Install packages on Fedora/RHEL
# -----------------------------------------------------------------------------
install_fedora() {
    log_info "Installing required packages..."
    sudo dnf install -y \
        cmake \
        make \
        gcc-c++ \
        gcc \
        git \
        valgrind \
        gh
}

# -----------------------------------------------------------------------------
# Install packages on Arch Linux
# -----------------------------------------------------------------------------
install_arch() {
    log_info "Installing required packages..."
    sudo pacman -S --needed --noconfirm \
        cmake \
        make \
        gcc \
        git \
        valgrind \
        github-cli
}

# -----------------------------------------------------------------------------
# Install packages on macOS via Homebrew
# -----------------------------------------------------------------------------
install_macos() {
    if ! is_installed brew; then
        log_error "Homebrew is not installed. Please install it first from https://brew.sh"
        exit 1
    fi

    log_info "Installing required packages via Homebrew..."
    brew install \
        cmake \
        make \
        gcc \
        git \
        valgrind \
        gh
}

# -----------------------------------------------------------------------------
# Configure Git commit template
# -----------------------------------------------------------------------------
setup_git_template() {
    local template_file=".gitmessage"

    if [ ! -f "$template_file" ]; then
        log_error "Template file '$template_file' not found in repository root."
        return 1
    fi

    log_info "Configuring Git commit template..."
    git config commit.template "$template_file"
    log_ok "Git commit template activated: git config commit.template .gitmessage"
}

# -----------------------------------------------------------------------------
# Verify installation
# -----------------------------------------------------------------------------
verify_installation() {
    local all_ok=true

    log_info "Verifying installation..."

    for cmd in cmake make gcc g++ git valgrind; do
        if is_installed "$cmd"; then
            local version=""
            case "$cmd" in
                cmake)  version=$(cmake --version 2>/dev/null | head -n1 | awk '{print $3}') ;;
                make)   version=$(make --version 2>/dev/null | head -n1 | awk '{print $3}') ;;
                gcc)    version=$(gcc --version 2>/dev/null | head -n1 | awk '{print $3}') ;;
                g++)    version=$(g++ --version 2>/dev/null | head -n1 | awk '{print $3}') ;;
                git)    version=$(git --version 2>/dev/null | awk '{print $3}') ;;
                valgrind) version=$(valgrind --version 2>/dev/null | awk '{print $3}') ;;
            esac
            log_ok "$cmd $version is installed"
        else
            log_warn "$cmd is not installed"
            all_ok=false
        fi
    done

    if is_installed gh; then
        log_ok "gh $(gh --version 2>/dev/null | head -n1 | awk '{print $3}') is installed"
    else
        log_warn "gh (GitHub CLI) is not installed. Some scripts (new-work.sh, sync-develop.sh, sync-main.sh) require it."
    fi

    if git config commit.template &>/dev/null; then
        log_ok "Git commit template is configured: $(git config commit.template)"
    else
        log_warn "Git commit template is not configured."
    fi

    return $all_ok
}

# -----------------------------------------------------------------------------
# Main function
# -----------------------------------------------------------------------------
main() {
    echo "========================================================================"
    log_info "ft_irc - Setup Script"
    log_info "This script installs project dependencies and configures the environment."
    echo "========================================================================"
    echo ""

    local distro
    distro=$(detect_distro)

    log_info "Detected distribution: $distro"

    case "$distro" in
        ubuntu|debian)
            install_debian
            ;;
        fedora|rhel|centos)
            install_fedora
            ;;
        arch)
            install_arch
            ;;
        macos)
            install_macos
            ;;
        *)
            log_error "Unsupported distribution: $distro"
            log_info "Please install the following packages manually:"
            echo "  cmake, make, gcc, g++, git, valgrind, gh (GitHub CLI)"
            exit 1
            ;;
    esac

    echo ""
    log_ok "Package installation complete."

    # Configure Git commit template
    setup_git_template

    echo ""
    log_info "Verifying installation..."
    if verify_installation; then
        echo ""
        log_ok "Setup complete! You are ready to contribute to ft_irc."
        echo ""
        echo "Next steps:"
        echo "  1. Create a feature branch: ./scripts/new-work.sh feature my-feature"
        echo "  2. Implement your changes"
        echo "  3. Push to develop: ./scripts/sync-develop.sh feature my-feature"
    else
        echo ""
        log_warn "Setup completed with some missing components. Please install them manually."
        echo ""
        echo "Required packages: cmake, make, gcc, g++, git, valgrind"
        echo "Optional: gh (GitHub CLI) for new-work.sh and sync scripts"
        exit 1
    fi
}

main "$@"
