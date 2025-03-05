# Hooks-Util Framework

## Useful Commands

### Installation Commands
- `git -C /path/to/project submodule add https://github.com/greggh/hooks-util.git .githooks/hooks-util` - Add as submodule
- `cd /path/to/project && .githooks/hooks-util/install.sh` - Install hooks in a project

### Git Commands
- `git -C /home/gregg/Projects/hooks-util status` - Check current status
- `git -C /home/gregg/Projects/hooks-util add .` - Stage all changes
- `git -C /home/gregg/Projects/hooks-util commit -m "message"` - Commit changes
- `git -C /home/gregg/Projects/hooks-util push` - Push changes

### Development Commands
- `stylua lua/ -c` - Check Lua formatting
- `stylua lua/` - Format Lua code
- `luacheck lua/` - Run Lua linter

## Planned Architecture

The hooks-util framework will use an adapter-based architecture:

```
hooks-util/
├── core/              # Core functionality
├── adapters/          # Project type adapters
│   ├── nvim-plugin/   # Neovim plugin adapter
│   ├── nvim-config/   # Neovim config adapter
│   └── lua-lib/       # Generic Lua library adapter
└── ci/                # CI platform implementations
    ├── github/        # GitHub Actions workflows
    ├── gitlab/        # GitLab CI configurations
    └── azure/         # Azure DevOps pipelines
```

### Features
- Lust-Next integration for standardized testing
- Linting configuration per project type
- Pre-commit hooks for version validation
- Multi-platform CI workflow templates
- Project type adapters for specific configurations

### Project Structure
- `core/` - Core functionality shared across all project types
- `adapters/` - Project-specific adapters
- `ci/` - CI platform implementations
- `install.sh` - Main installation script
- `README.md` - Framework documentation