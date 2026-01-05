# Neovim Configuration

Personal Neovim configuration with support for airgapped/offline installations.

## Features

- 🎨 **Theme**: Catppuccin
- 📁 **File Navigation**: Telescope, nvim-tree, Oil
- 🔍 **Search**: Fuzzy finding with Telescope + fzf-native
- 💡 **LSP**: Full LSP support via nvim-lspconfig and Mason
- ✨ **Autocompletion**: nvim-cmp with multiple sources
- 🌳 **Treesitter**: Advanced syntax highlighting
- 🔧 **Git Integration**: Gitsigns
- 📝 **Editing**: Auto-pairs, comments, flash navigation
- 🎯 **UI**: Lualine, bufferline, which-key, trouble

## Installation Methods

### Option 1: Online Installation (Internet Required)

Clone and install with plugins:

```bash
git clone git@github.com:philippstreller/nvim.git ~/.config/nvim
cd ~/.config/nvim
./install.sh online
```

### Option 2: Airgapped Installation (No Internet Required)

Perfect for isolated/secure environments or offline machines.

#### On a machine with internet access:

```bash
# Clone the repository
git clone git@github.com:philippstreller/nvim.git
cd nvim

# Build the airgapped transfer package
./install.sh airgapped
```

This creates `~/nvim-airgapped-transfer/` containing:
- Neovim v0.10.3 binary for Linux x64
- Complete config with all 29 plugins pre-installed
- Automated installation script
- Documentation

#### Transfer to airgapped machine:

Copy the `~/nvim-airgapped-transfer/` directory to your target Linux machine using:
- USB drive
- SCP/SFTP (if available before air-gapping)
- Physical media
- Approved transfer method

#### On the airgapped Linux machine:

```bash
cd nvim-airgapped-transfer
chmod +x INSTALL.sh
./INSTALL.sh
```

Then restart your shell or `source ~/.bashrc` and start with `nvim`.

## Key Bindings

Leader key: `<Space>`

### Navigation
- `<Space>ff` - Find files
- `<Space>fg` - Live grep
- `<Space>fb` - Browse buffers
- `<Space>fh` - Help tags
- `<Space>e` - Toggle file explorer
- `<Space>-` - Open oil.nvim (edit filesystem like buffer)

### LSP
- `gd` - Go to definition
- `gr` - Find references
- `K` - Hover documentation
- `<Space>ca` - Code actions
- `<Space>rn` - Rename symbol
- `[d` / `]d` - Navigate diagnostics

### Editing
- `gcc` - Toggle line comment
- `gc` (visual) - Toggle comment selection
- `s` + 2 chars - Flash jump to location

### Management
- `:Lazy` - Plugin manager
- `:Mason` - LSP server installer
- `:checkhealth` - Check Neovim health

## Requirements

### For Online Installation
- Neovim >= 0.9.0
- Git
- Node.js (for some LSP servers via Mason)
- A C compiler (for telescope-fzf-native)
- ripgrep (for live grep in Telescope)

### For Airgapped Installation
- Linux x64 system
- ~50MB disk space
- Bash shell
- No root access needed

## Included Plugins (29)

- **UI/Theme**: catppuccin, lualine, bufferline, indent-blankline, mini.icons
- **File Navigation**: telescope, telescope-fzf-native, nvim-tree, oil.nvim
- **LSP/Completion**: nvim-lspconfig, mason, mason-lspconfig, nvim-cmp, cmp-nvim-lsp, cmp-buffer, cmp-path, cmp-cmdline
- **Snippets**: LuaSnip, cmp_luasnip
- **Syntax**: nvim-treesitter
- **Git**: gitsigns
- **Editing**: Comment.nvim, nvim-autopairs, flash.nvim
- **Utilities**: which-key, trouble, plenary

## Customization

Configuration is organized in `lua/plugins/` with each plugin in its own file:

```
~/.config/nvim/
├── init.lua              # Main config
├── install.sh            # Installation script
└── lua/
    └── plugins/
        ├── theme.lua
        ├── lsp.lua
        ├── cmp.lua
        └── ...
```

Edit any plugin file to customize behavior.

## Updating

### Online Installation

```bash
cd ~/.config/nvim
git pull
nvim
# Then in Neovim: :Lazy sync
```

### Airgapped Installation

Re-build the airgapped package on a machine with internet and transfer again:

```bash
cd /path/to/nvim
git pull
./install.sh airgapped
# Transfer ~/nvim-airgapped-transfer/ to target machine
```

## Troubleshooting

### Neovim not found after installation
```bash
# Add to PATH
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

### LSP servers not working
On online installations, install LSP servers via Mason:
```vim
:Mason
```

On airgapped installations, LSP servers must be installed separately or bundled manually.

### Telescope live grep not working
Install ripgrep:
```bash
# Ubuntu/Debian
sudo apt install ripgrep

# macOS
brew install ripgrep
```

## License

MIT

## Repository

https://github.com/philippstreller/nvim
