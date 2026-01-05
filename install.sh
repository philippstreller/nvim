#!/usr/bin/env bash
set -e

# Neovim Configuration Installer
# Usage:
#   ./install.sh online   - Install config and download plugins (requires internet)
#   ./install.sh offline  - Install from bundled archive (no internet required)
#   ./install.sh bundle   - Create offline bundle for distribution

NVIM_CONFIG_DIR="${HOME}/.config/nvim"
NVIM_DATA_DIR="${HOME}/.local/share/nvim"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if nvim is installed
check_nvim() {
    if ! command -v nvim &> /dev/null; then
        log_error "Neovim is not installed. Please install it first:"
        echo "  Ubuntu/Debian: sudo apt install neovim"
        echo "  macOS: brew install neovim"
        echo "  RHEL/CentOS: sudo yum install neovim"
        exit 1
    fi
    log_info "Neovim found: $(nvim --version | head -n1)"
}

# Backup existing config
backup_existing() {
    if [ -d "$NVIM_CONFIG_DIR" ]; then
        BACKUP_DIR="${NVIM_CONFIG_DIR}.backup.$(date +%Y%m%d_%H%M%S)"
        log_warn "Existing config found. Backing up to: $BACKUP_DIR"
        mv "$NVIM_CONFIG_DIR" "$BACKUP_DIR"
    fi
}

# Install online (download plugins)
install_online() {
    log_info "Installing Neovim config (online mode)..."

    backup_existing

    # Copy config files
    log_info "Copying configuration files..."
    mkdir -p "$(dirname "$NVIM_CONFIG_DIR")"
    cp -r "$SCRIPT_DIR" "$NVIM_CONFIG_DIR"

    # Remove install script and bundles from config
    rm -f "$NVIM_CONFIG_DIR/install.sh"
    rm -f "$NVIM_CONFIG_DIR"/*.tar.gz

    # Bootstrap lazy.nvim and install plugins
    log_info "Installing plugins (this may take a few minutes)..."
    nvim --headless "+Lazy! sync" +qa

    log_info "✓ Installation complete!"
    log_info "Start Neovim with: nvim"
}

# Install offline (from bundle)
install_offline() {
    log_info "Installing Neovim config (offline mode)..."

    BUNDLE_FILE="$SCRIPT_DIR/nvim-bundle.tar.gz"

    if [ ! -f "$BUNDLE_FILE" ]; then
        log_error "Bundle file not found: $BUNDLE_FILE"
        log_error "Create one with: ./install.sh bundle"
        exit 1
    fi

    backup_existing

    # Extract bundle
    log_info "Extracting bundle..."
    tar -xzf "$BUNDLE_FILE" -C "$HOME"

    log_info "✓ Installation complete!"
    log_info "Start Neovim with: nvim"
}

# Create bundle for offline distribution
create_bundle() {
    log_info "Creating offline bundle..."

    if [ ! -d "$NVIM_CONFIG_DIR" ]; then
        log_error "Neovim config not found at: $NVIM_CONFIG_DIR"
        exit 1
    fi

    if [ ! -d "$NVIM_DATA_DIR/lazy" ]; then
        log_error "Plugins not found. Run Neovim first to install plugins."
        exit 1
    fi

    BUNDLE_NAME="nvim-bundle.tar.gz"
    TEMP_DIR=$(mktemp -d)

    # Copy config (excluding bundles and git)
    log_info "Copying config files..."
    mkdir -p "$TEMP_DIR/.config"
    cp -r "$NVIM_CONFIG_DIR" "$TEMP_DIR/.config/"
    rm -rf "$TEMP_DIR/.config/nvim/.git"
    rm -f "$TEMP_DIR/.config/nvim"/*.tar.gz
    rm -f "$TEMP_DIR/.config/nvim/install.sh"

    # Copy plugins
    log_info "Copying plugins..."
    mkdir -p "$TEMP_DIR/.local/share/nvim"
    cp -r "$NVIM_DATA_DIR/lazy" "$TEMP_DIR/.local/share/nvim/"

    # Create archive
    log_info "Creating archive..."
    cd "$TEMP_DIR"
    tar -czf "$BUNDLE_NAME" .config .local
    mv "$BUNDLE_NAME" "$SCRIPT_DIR/"
    cd - > /dev/null

    # Cleanup
    rm -rf "$TEMP_DIR"

    BUNDLE_SIZE=$(du -h "$SCRIPT_DIR/$BUNDLE_NAME" | cut -f1)
    log_info "✓ Bundle created: $SCRIPT_DIR/$BUNDLE_NAME ($BUNDLE_SIZE)"
    log_info ""
    log_info "Distribution instructions:"
    log_info "1. Transfer bundle to target machine"
    log_info "2. Run: tar -xzf $BUNDLE_NAME -C ~/"
    log_info "3. Start Neovim: nvim"
}

# Show usage
show_usage() {
    cat << EOF
Neovim Configuration Installer

Usage:
  ./install.sh online   - Install config and download plugins (requires internet)
  ./install.sh offline  - Install from bundled archive (no internet required)
  ./install.sh bundle   - Create offline bundle for distribution

Examples:
  # On your machine (create bundle)
  ./install.sh bundle

  # On colleague's machine (with internet)
  ./install.sh online

  # On EC2 instance (no internet)
  scp nvim-bundle.tar.gz ec2-instance:~/
  ssh ec2-instance "tar -xzf nvim-bundle.tar.gz -C ~/"

EOF
}

# Main
main() {
    check_nvim

    case "${1:-}" in
        online)
            install_online
            ;;
        offline)
            install_offline
            ;;
        bundle)
            create_bundle
            ;;
        *)
            show_usage
            exit 1
            ;;
    esac
}

main "$@"
