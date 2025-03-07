
# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Added

- Comprehensive testing strategy in TESTING.md
- Automated test script for validating across adapter types (scripts/test_all_adapters.sh)
- GitHub workflow validation script (scripts/test_github_workflows.sh)
- Improved CI workflow with enhanced testing that doesn't skip checks
- Fixed markdown validation in docs.yml without disabling checks

### Fixed

- Infinite recursion issues in pre-commit hook by adding HOOKS_PROCESSING_QUALITY flag
- Enhanced shellcheck detection with better fallback mechanisms
- Template file creation in update_hook.sh for both normal and testbed projects
- Fix for CI workflow failures by implementing proper environment mocking
- Properly handling GitHub Actions environment constraints without disabling checks

## [0.6.0] - 2024-03-01

### Added

- Documentation linting with markdown module
- Pre-commit hook updates for better error messages
- YAML, JSON, and TOML linting capabilities
- Enhanced hooks_fix_staged_quality with improved error handling
- Template system for linting configurations

### Changed

- Restructured core library with better organization
- Improved adapter-based project type detection
- Enhanced error messages and debugging support
- Updated installation script for better environment handling

### Fixed

- Path resolution issues with various environment types
- Config loading problems in some edge cases
- Missing template file creation during installation
- Workflow execution problems in CI environments

## [0.5.0] - 2024-02-15

### Added

- Initial support for documentation projects
- YAML validation in GitHub workflows
- Auto-detection of project type during installation
- Enhanced testing capabilities with lust-next integration

### Changed

- Improved adapter architecture for better extensibility
- Enhanced installation script with proper error handling
- Streamlined configuration loading process

### Fixed

- Issues with nested project structures
- Path resolution in various environments
- Template distribution across project types

## [0.4.0] - 2024-01-30

### Added

- Support for Neovim config projects
- Workflow validation for CI environments
- Markdown documentation validation
- Enhanced shell script validation

### Changed

- Standardized error codes and handling
- Improved debugging support with detailed logs
- Better detection of required tools

### Fixed

- Issues with paths containing spaces
- Problems with tool detection on different platforms

## [0.3.0] - 2024-01-15

### Added

- Support for Lua library projects
- Luacheck integration for Lua code validation
- StyLua integration for code formatting
- ShellCheck integration for shell script validation

### Changed

- Modular architecture with adapter system
- Improved project structure detection
- Enhanced error reporting

## [0.2.1] - 2024-01-10

### Added

- CI workflow modifications for GitHub Actions compatibility
- Diagnostic test approach that validates core functionality
- Fix-markdown.sh script for normalizing Markdown files

### Fixed

- Integration tests that require a full Git environment
- Documentation workflow with more lenient markdownlint checks

## [0.2.0] - 2024-01-05

### Added

- Support for Neovim plugin projects
- Pre-commit hook for code quality verification
- Basic installation script

### Changed

- Improved code organization
- Better error handling

## [0.1.0] - 2023-12-20

### Added

- Initial project structure
- Basic Git hooks functionality
- Core library modules

