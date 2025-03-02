# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Advanced configuration system with layered configuration files:
  - `.hooksrc.local.example` for machine-specific settings
  - `.hooksrc.user.example` for user-specific preferences
- Enhanced configuration loading with priority ordering
- Improved installation script that copies example configuration files

### Changed
- Comprehensive documentation updates:
  - Expanded DEVELOPMENT.md with detailed installation instructions for all platforms
  - Enhanced SECURITY.md with hook-specific security considerations
  - Updated SUPPORT.md with community resources and troubleshooting tips
  - Improved docs/README.md with hook development best practices
  - Customized GitHub issue and PR templates for the hooks utility project

## [0.1.0] - 2025-03-02

### Added
- Core utility functions for pre-commit hooks
- Error handling and reporting system with fallback mechanisms
- Path handling utilities for cross-platform compatibility
- Configuration system via .hooksrc template
- Ready-to-use pre-commit hook implementation
- StyLua integration with fallback mechanisms
- Installation script with customization options
- Comprehensive documentation and examples
- Project structure based on GitHub best practices

### Planned
- Luacheck integration for linting Lua files
- Test runner integration for Neovim projects
- Automatic fixes for common issues:
  - Trailing whitespace
  - Line endings
  - Unused variables
  - Missing module imports

[Unreleased]: https://github.com/greggh/hooks-util/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/greggh/hooks-util/releases/tag/v0.1.0