# Development Guide for Neovim Hooks Utilities

This document provides instructions for setting up your development environment and outlines the development workflow for the Neovim Hooks Utilities project.

## Prerequisites

- **Bash**: Version 4.0 or higher for script execution
- **Git**: For version control
- **StyLua**: For Lua code formatting
- **Luacheck**: For Lua static analysis (for testing hooks)
- **Neovim**: Version 0.8.0 or higher (for testing hooks)
- **ShellCheck**: For shell script linting (recommended for development)

## Setting Up Your Development Environment

### Clone the Repository

```bash
git clone https://github.com/greggh/hooks-util.git
cd hooks-util
```

### Install Dependencies

#### Linux

##### Ubuntu/Debian

```bash
# Install basic tools
sudo apt-get update
sudo apt-get install git make luarocks shellcheck

# Install Luacheck
sudo luarocks install luacheck

# Install StyLua
curl -L -o stylua.zip $(curl -s https://api.github.com/repos/JohnnyMorganz/StyLua/releases/latest | grep -o "https://.*stylua-linux-x86_64.zip")
unzip stylua.zip
chmod +x stylua
sudo mv stylua /usr/local/bin/
```

##### Arch Linux

```bash
# Install basic tools
sudo pacman -S git make luarocks shellcheck

# Install Luacheck
sudo luarocks install luacheck

# Install StyLua using yay
yay -S stylua

# Or install StyLua using paru
# paru -S stylua
```

##### Fedora

```bash
# Install basic tools
sudo dnf install git make luarocks ShellCheck

# Install Luacheck
sudo luarocks install luacheck

# Install StyLua
curl -L -o stylua.zip $(curl -s https://api.github.com/repos/JohnnyMorganz/StyLua/releases/latest | grep -o "https://.*stylua-linux-x86_64.zip")
unzip stylua.zip
chmod +x stylua
sudo mv stylua /usr/local/bin/
```

#### macOS

```bash
# Install Homebrew if not already installed
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install basic tools
brew install git luarocks shellcheck

# Install Luacheck
luarocks install luacheck

# Install StyLua
brew install stylua
```

#### Windows

##### Using Scoop

```powershell
# Install scoop if not already installed
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression

# Install basic tools
scoop install git make
scoop install shellcheck

# Install luarocks
scoop install luarocks

# Install luacheck
luarocks install luacheck

# Install stylua
scoop install stylua
```

##### Using Chocolatey

```powershell
# Install chocolatey if not already installed
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Install basic tools
choco install git make shellcheck

# Install luarocks
choco install luarocks

# Install luacheck
luarocks install luacheck

# Install stylua (download from GitHub)
# Visit https://github.com/JohnnyMorganz/StyLua/releases and download the Windows version
# Add the stylua executable to your PATH
```

##### Using WSL (recommended)

For the best development experience on Windows, we recommend using Windows Subsystem for Linux (WSL):

```bash
# Install WSL with Ubuntu
wsl --install

# Then follow the Ubuntu/Debian instructions above
```

### Configure Development Environment

Set up Git hooks for your local development:

```bash
# Install hooks in the project repository itself
./install.sh --config

# Create local configuration
cp .hooksrc.local.example .hooksrc.local
```

## Development Workflow

### Branching Strategy

- `main` - Production-ready code
- `develop` - Integration branch for features
- Feature branches - Named `feature/your-feature`
- Bugfix branches - Named `bugfix/issue-description`

### Testing Changes

You can test your changes by installing the hooks in a test repository:

```bash
# From your test repository:
/path/to/hooks-util/install.sh --config --verbose
```

### Testing Scripts

```bash
# Test common utilities
bash -x lib/common.sh

# Test a specific hook manually
bash -x hooks/pre-commit

# Lint shell scripts with ShellCheck
shellcheck lib/*.sh hooks/* install.sh
```

### Adding New Functionality

When adding new functionality:

1. Create a new module in the `lib/` directory for related functions
2. Update the hooks in the `hooks/` directory to use the new functionality
3. Add example configuration in the `templates/` directory
4. Update documentation in the `README.md` and other relevant files
5. Update the `CHANGELOG.md` with your changes

## Release Process

1. Update version number in `lib/version.sh`
2. Update `CHANGELOG.md` to move unreleased changes to a new version section
3. Create a new release branch `release/vX.Y.Z`
4. Create a pull request to `main`
5. After approval and merge, tag the release on GitHub

## Directory Structure

```
hooks-util/
├── hooks/              # Ready-to-use Git hooks
│   └── pre-commit      # Pre-commit hook implementation
├── lib/                # Utility libraries
│   ├── common.sh       # Common functions
│   ├── error.sh        # Error handling utilities
│   ├── path.sh         # Path handling utilities
│   ├── stylua.sh       # StyLua integration
│   └── version.sh      # Version information
├── templates/          # Configuration templates
│   └── hooksrc.template # Template for .hooksrc file
├── examples/           # Example usage
├── docs/               # Documentation
└── scripts/            # Utility scripts
```

## Common Issues and Solutions

### StyLua Not Found

If you encounter "StyLua not found" errors:
1. Check that StyLua is installed: `which stylua`
2. Ensure it's in your PATH
3. Set the path explicitly in `.hooksrc.local`: `HOOKS_STYLUA_PATH=/path/to/stylua`

### Hooks Not Running

If hooks aren't running:
1. Verify that Git is using the hooks: `git config core.hooksPath`
2. Check hook permissions: `ls -la .githooks/`
3. Ensure scripts have execute permission: `chmod +x .githooks/*`

### Path Issues on Windows

If you encounter path-related issues on Windows:
1. Use Git Bash or WSL for more consistent behavior
2. Check path normalization by adding `set -x` to the hook script

## Additional Resources

- [Git Hooks Documentation](https://git-scm.com/docs/githooks)
- [ShellCheck](https://www.shellcheck.net/) - For validating shell scripts
- [StyLua Documentation](https://github.com/JohnnyMorganz/StyLua)
- [Luacheck Documentation](https://github.com/lunarmodules/luacheck)

## Getting Help

If you encounter any issues during development, please check the [SUPPORT.md](SUPPORT.md) file for ways to get help from the community.