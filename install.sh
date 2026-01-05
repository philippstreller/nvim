#!/usr/bin/env bash
set -e

# Neovim Configuration Installer
# Usage:
#   ./install.sh online      - Install config and download plugins (requires internet)
#   ./install.sh offline     - Install from bundled archive (no internet required)
#   ./install.sh bundle      - Create offline bundle for distribution
#   ./install.sh airgapped   - Build complete airgapped transfer package (Linux x64)

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

# Build airgapped transfer package
build_airgapped() {
    log_info "Building airgapped transfer package for Linux x64..."

    OUTPUT_DIR="$HOME/nvim-airgapped-transfer"

    # Create output directory
    mkdir -p "$OUTPUT_DIR"

    # Step 1: Download Neovim binary for Linux x64
    log_info "Downloading Neovim binaries for Linux x64..."
    NVIM_TAR_URL="https://github.com/neovim/neovim/releases/download/v0.10.3/nvim-linux64.tar.gz"
    NVIM_APPIMAGE_URL="https://github.com/neovim/neovim/releases/download/v0.10.3/nvim.appimage"

    if command -v curl &> /dev/null; then
        curl -L "$NVIM_TAR_URL" -o "$OUTPUT_DIR/nvim-linux64.tar.gz"
        curl -L "$NVIM_APPIMAGE_URL" -o "$OUTPUT_DIR/nvim.appimage"
    elif command -v wget &> /dev/null; then
        wget "$NVIM_TAR_URL" -O "$OUTPUT_DIR/nvim-linux64.tar.gz"
        wget "$NVIM_APPIMAGE_URL" -O "$OUTPUT_DIR/nvim.appimage"
    else
        log_error "Neither curl nor wget found. Cannot download Neovim binary."
        exit 1
    fi

    if [ ! -f "$OUTPUT_DIR/nvim-linux64.tar.gz" ] || [ ! -s "$OUTPUT_DIR/nvim-linux64.tar.gz" ]; then
        log_error "Failed to download Neovim tar.gz"
        exit 1
    fi

    if [ ! -f "$OUTPUT_DIR/nvim.appimage" ] || [ ! -s "$OUTPUT_DIR/nvim.appimage" ]; then
        log_error "Failed to download Neovim AppImage"
        exit 1
    fi

    chmod +x "$OUTPUT_DIR/nvim.appimage"

    log_info "✓ Neovim binaries downloaded (tar.gz + AppImage)"

    # Step 2: Create plugin bundle
    log_info "Creating plugin bundle..."

    if [ ! -d "$NVIM_DATA_DIR/lazy" ]; then
        log_error "Plugins not found. Install them first with: ./install.sh online"
        exit 1
    fi

    TEMP_DIR=$(mktemp -d)
    mkdir -p "$TEMP_DIR/.config"
    cp -r "$NVIM_CONFIG_DIR" "$TEMP_DIR/.config/"
    rm -rf "$TEMP_DIR/.config/nvim/.git"
    rm -rf "$TEMP_DIR/.config/nvim/.github"
    rm -f "$TEMP_DIR/.config/nvim"/*.tar.gz
    rm -f "$TEMP_DIR/.config/nvim/install.sh"

    mkdir -p "$TEMP_DIR/.local/share/nvim"
    cp -r "$NVIM_DATA_DIR/lazy" "$TEMP_DIR/.local/share/nvim/"

    cd "$TEMP_DIR"
    # Create archive without macOS extended attributes
    COPYFILE_DISABLE=1 tar -czf nvim-bundle.tar.gz .config .local
    mv nvim-bundle.tar.gz "$OUTPUT_DIR/"
    cd - > /dev/null
    rm -rf "$TEMP_DIR"

    log_info "✓ Plugin bundle created"

    # Step 3: Create installation script
    log_info "Creating installation script..."

    cat > "$OUTPUT_DIR/INSTALL.sh" << 'EOFINSTALL'
#!/usr/bin/env bash
set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log_info "=== Neovim Airgapped Installation ==="
echo ""

if [[ "$(uname -s)" != "Linux" ]]; then
    log_error "This script is for Linux x64 systems. Current: $(uname -s)"
    exit 1
fi

log_info "Step 1/3: Installing Neovim binary..."

# Check GLIBC version to determine which binary to use
GLIBC_VERSION=$(ldd --version 2>&1 | head -n1 | grep -oP '\d+\.\d+$' || echo "0.0")
USE_APPIMAGE=false

# Try standard binary first
if [ -f "$SCRIPT_DIR/nvim-linux64.tar.gz" ]; then
    mkdir -p ~/.local
    log_info "Extracting Neovim to ~/.local..."
    tar -xzf "$SCRIPT_DIR/nvim-linux64.tar.gz" -C ~/.local/ 2>/dev/null || true
    mkdir -p ~/.local/bin
    ln -sf ~/.local/nvim-linux64/bin/nvim ~/.local/bin/nvim

    # Test if it works
    export PATH="$HOME/.local/bin:$PATH"
    if ~/.local/bin/nvim --version &>/dev/null; then
        log_info "✓ Using standard Neovim binary"
    else
        log_warn "Standard binary failed (GLIBC incompatibility detected)"
        USE_APPIMAGE=true
    fi
else
    USE_APPIMAGE=true
fi

# Fall back to AppImage if standard binary doesn't work
if [ "$USE_APPIMAGE" = true ]; then
    if [ -f "$SCRIPT_DIR/nvim.appimage" ]; then
        log_info "Using Neovim AppImage (compatible with older systems)..."
        mkdir -p ~/.local/bin
        cp "$SCRIPT_DIR/nvim.appimage" ~/.local/bin/nvim
        chmod +x ~/.local/bin/nvim
        log_info "✓ AppImage installed"
    else
        log_error "Neither standard binary nor AppImage could be installed"
        exit 1
    fi
fi

# Ensure PATH is set
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    log_warn "~/.local/bin is not in PATH. Add to ~/.bashrc:"
    echo '    export PATH="$HOME/.local/bin:$PATH"'
    read -p "Add to ~/.bashrc now? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo '' >> ~/.bashrc
        echo '# Neovim PATH' >> ~/.bashrc
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
        log_info "Added to ~/.bashrc"
    fi
fi

log_info "✓ Neovim binary installed"

log_info "Step 2/3: Installing configuration and plugins..."
if [ ! -f "$SCRIPT_DIR/nvim-bundle.tar.gz" ]; then
    log_error "Configuration bundle not found"
    exit 1
fi

if [ -d ~/.config/nvim ]; then
    BACKUP_DIR="$HOME/.config/nvim.backup.$(date +%Y%m%d_%H%M%S)"
    log_warn "Backing up existing config to: $BACKUP_DIR"
    mv ~/.config/nvim "$BACKUP_DIR"
fi

tar -xzf "$SCRIPT_DIR/nvim-bundle.tar.gz" -C ~/
log_info "✓ Configuration installed"

log_info "Step 3/3: Verifying installation..."
export PATH="$HOME/.local/bin:$PATH"

if command -v nvim &> /dev/null; then
    log_info "✓ Neovim: $(nvim --version | head -n1)"
else
    log_error "Neovim not found. Restart shell or: source ~/.bashrc"
    exit 1
fi

[ -f ~/.config/nvim/init.lua ] && log_info "✓ Config found" || { log_error "Config missing!"; exit 1; }
[ -d ~/.local/share/nvim/lazy ] && log_info "✓ Plugins installed" || { log_error "Plugins missing!"; exit 1; }

echo ""
log_info "=== Installation Complete! ==="
log_info "Start with: nvim"
log_info "Leader key: <Space>"
log_info "Find files: <Space>ff | Grep: <Space>fg"
EOFINSTALL

    chmod +x "$OUTPUT_DIR/INSTALL.sh"
    log_info "✓ Installation script created"

    # Step 4: Create README
    log_info "Creating README..."

    cat > "$OUTPUT_DIR/README.md" << 'EOFREADME'
# Neovim Airgapped Installation Package

Complete offline installation package for Linux x64 systems.

## Contents

- `nvim-linux64.tar.gz` - Neovim v0.10.3 binary (requires GLIBC 2.29+)
- `nvim.appimage` - Neovim v0.10.3 AppImage (for older systems like RHEL 8)
- `nvim-bundle.tar.gz` - Config + pre-installed plugins
- `INSTALL.sh` - Automated installer (auto-detects which binary to use)
- `README.md` - This file

## Quick Start

Transfer this directory to your Linux machine and run:

```bash
cd nvim-airgapped-transfer
chmod +x INSTALL.sh
./INSTALL.sh
```

Then restart your shell or run `source ~/.bashrc` and start with `nvim`.

## Manual Installation

```bash
# Install Neovim (choose one method)

# Method 1: Standard binary (newer systems with GLIBC 2.29+)
mkdir -p ~/.local
tar -xzf nvim-linux64.tar.gz -C ~/.local/
mkdir -p ~/.local/bin
ln -sf ~/.local/nvim-linux64/bin/nvim ~/.local/bin/nvim
export PATH="$HOME/.local/bin:$PATH"

# Method 2: AppImage (older systems like RHEL 8, CentOS 8)
mkdir -p ~/.local/bin
cp nvim.appimage ~/.local/bin/nvim
chmod +x ~/.local/bin/nvim
export PATH="$HOME/.local/bin:$PATH"

# Install config
tar -xzf nvim-bundle.tar.gz -C ~/
nvim
```

## Key Bindings

- `<Space>` - Leader
- `<Space>ff` - Find files
- `<Space>fg` - Live grep
- `<Space>e` - File explorer
- `:Lazy` - Plugin manager
- `:Mason` - LSP servers

## Requirements

- Linux x64 system
- ~50MB disk space
- No root access needed
- No internet required

---

Package built: $(date +%Y-%m-%d)
Neovim: v0.10.3
EOFREADME

    log_info "✓ README created"

    # Show summary
    echo ""
    log_info "=== Airgapped Package Built Successfully! ==="
    echo ""
    log_info "Location: $OUTPUT_DIR"
    log_info "Contents:"
    ls -lh "$OUTPUT_DIR" | tail -n +2 | awk '{printf "  - %-30s %s\n", $9, $5}'
    echo ""
    log_info "Total size: $(du -sh "$OUTPUT_DIR" | cut -f1)"
    echo ""
    log_info "Next steps:"
    log_info "1. Transfer $OUTPUT_DIR to your Linux machine"
    log_info "2. Run: cd nvim-airgapped-transfer && ./INSTALL.sh"
    echo ""
}

# Show usage
show_usage() {
    cat << EOF
Neovim Configuration Installer

Usage:
  ./install.sh online      - Install config and download plugins (requires internet)
  ./install.sh offline     - Install from bundled archive (no internet required)
  ./install.sh bundle      - Create offline bundle for distribution
  ./install.sh airgapped   - Build complete airgapped transfer package (Linux x64)

Examples:
  # Install locally with plugins
  ./install.sh online

  # Build airgapped package for Linux transfer
  ./install.sh airgapped

  # On airgapped Linux machine
  ./INSTALL.sh

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
        airgapped)
            build_airgapped
            ;;
        *)
            show_usage
            exit 1
            ;;
    esac
}

main "$@"
