# hooks-util v0.6.0 Changes

This document summarizes the enhancements made in hooks-util v0.6.0, which includes significant improvements to the core functionality and adapter system.

## Core Enhancements

### Documentation Validation Tools

- Added comprehensive Markdown linting and fixing capabilities:
  - New `core/markdown.lua` module for markdown validation
  - Integration with markdownlint-cli
  - Comprehensive fixing scripts for common markdown issues:
    - List numbering
    - Heading levels
    - Code blocks
    - Newlines
    - Comprehensive fixes

- Added YAML linting capabilities:
  - New `core/yaml.lua` module
  - Integration with yamllint
  - Configuration template

- Added JSON linting support:
  - New `core/json.lua` module
  - Integration with jsonlint
  - Configuration template

- Added TOML linting support:
  - New `core/toml.lua` module
  - Integration with TOML validation tools
  - Configuration template

### GitHub Workflow Management

- Added a workflow management system:
  - New `core/workflows.lua` module
  - Base workflow templates in `ci/github/workflows/`
  - Adapter-specific configurations in `ci/github/configs/`
  - Workflow merging functionality to combine base workflows with adapter configurations
  - Support for various workflow types (CI, markdown-lint, yaml-lint, etc.)

### Submodule Update Mechanism

- Added a robust mechanism for handling hooks-util as a git submodule:
  - New `post-submodule-update` hook
  - `gitmodules-hooks.sh` script to wrap git commands and detect submodule updates
  - Automatic update of hooks when the hooks-util submodule is updated
  - Backup and versioning system to preserve customizations
  - Detailed documentation on submodule update usage

### Installation Enhancements

- Improved installation script:
  - Proper version checking for updates
  - File-by-file update verification
  - Automatic backup of existing files before updating
  - Support for check-only mode to detect needed updates
  - Better error handling and reporting
  - Enhanced diagnostics

## Adapter Enhancements

### Neovim Plugin Adapter

- Enhanced with specialized validations:
  - Health check validation
  - Runtime path validation
  - Plugin structure validation
  - Adapter-specific CI workflow configuration

### Lua Library Adapter

- Enhanced with specialized capabilities:
  - Code coverage tracking support
  - LuaRocks validation
  - Multi-version testing
  - Adapter-specific CI workflow configuration

### Neovim Config Adapter

- Enhanced with specialized features:
  - Mock Neovim environment
  - Config validation
  - Plugin loading verification
  - Adapter-specific workflow configuration

### New Documentation Adapter

- Added a dedicated adapter for documentation projects:
  - MkDocs configuration validation
  - Documentation structure validation
  - Cross-reference validation
  - Adapter-specific workflow configuration

## Documentation

- Added detailed documentation for new features:
  - `submodule-update.md` - Guide for using hooks-util as a submodule
  - `version-0.6.0-changes.md` - This document
  - Enhanced README.md with new features

## Usage

To take advantage of these new features, run the installation script in your project:

```bash
env -C /path/to/your/project /path/to/hooks-util/install.sh
```

The installation script will detect your project type and install the appropriate hooks and configurations.

For submodule updates, follow the instructions in `docs/submodule-update.md`.

## Compatibility

hooks-util v0.6.0 is backward compatible with previous versions, but provides significant new functionality. Existing projects using hooks-util will automatically benefit from the new features when they update.