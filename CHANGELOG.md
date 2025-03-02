# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed
- Pre-commit hook now correctly exits with non-zero status when errors are found
- Missing tools are handled more gracefully during testing
- Integration tests now run successfully with proper error handling
- Fixed path handling issues in test environment
- Added proper error tracking and reporting in hooks
- Improved code quality checks for whitespace and unused variables
- Fixed test reliability issues with consistent cleanup

### Added
- Comprehensive integration test suite:
  - Basic functionality tests for core hook features
  - Neovim configuration project integration tests
  - Plugin project integration tests
- Test pre-commit hook for reliable testing with:
  - Improved error detection and reporting
  - Better whitespace and code style checking
  - Enhanced pattern matching for issues
- Multiple test runner options:
  - Standard test runner for CI environments
  - Simplified runner for better debugging
  - Individual test execution support
- Release candidate tagging for pre-release testing

## [0.2.0] - 2025-03-02

### Added
- Luacheck integration for linting Lua files:
  - Automatic configuration discovery
  - Support for different Luacheck config file formats
  - Clean error reporting and handling
  - Integration with pre-commit hook
- ShellCheck integration for validating shell scripts:
  - Automatic shell script detection (extension and shebang)
  - Standard error reporting
  - Required validation for all shell script commits
  - Cross-platform compatibility
- Test runner for Neovim projects:
  - Automatic test framework detection (Plenary, Makefile, Busted)
  - Support for different project structures
  - Configuration options for timeout and verbosity
  - Pre-commit integration for test verification
- Code quality improvement utilities:
  - Fix trailing whitespace automatically
  - Ensure proper line endings (LF not CRLF)
  - Add final newline to files
  - Prefix unused variables with underscore
  - Staged file fix-up before commit
- GitHub workflows and CI/CD integration:
  - CI workflow for shell script testing
  - Documentation testing and validation
  - Release automation workflow
  - Dependabot configuration for dependencies
- Testing infrastructure:
  - Unit testing framework for shell scripts
  - Integration test runners
  - Test helper functions and assertions
  - Example tests for core functionality
- Community management tools:
  - Saved replies for common interactions
  - Issue and PR response process documentation
  - Structured markdown documentation

### Changed
- Enhanced the configuration system:
  - Added layered configuration files (`.hooksrc.local.example` and `.hooksrc.user.example`)
  - Implemented priority-based configuration loading
  - Improved configuration option documentation
- Expanded documentation with:
  - API references for all modules
  - Usage examples with complete code
  - Configuration reference guide
  - Hook type explanations
  - Error code lookup and troubleshooting
  - Detailed installation instructions for all platforms
  - Hook-specific security considerations
  - Community resources and troubleshooting tips

### Improved
- Core error handling with better context reporting
- Path resolution for cross-platform compatibility
- StyLua integration with more robust fallbacks
- Pre-commit hook execution flow and reporting

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
- Support for additional hook types:
  - pre-push hooks for deployment validation
  - post-checkout hooks for environment setup
  - post-merge hooks for dependency management
- Module import detection and auto-correction
- Advanced test result reporting and formatting
- Integration with LSP servers for better diagnostics

[Unreleased]: https://github.com/greggh/hooks-util/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/greggh/hooks-util/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/greggh/hooks-util/releases/tag/v0.1.0