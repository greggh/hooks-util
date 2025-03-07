# Hooks-Util Changes Log

## Version 0.6.0 (2025-03-07)

### Fixed Pre-commit Hook Integration Issues

1. **Fixed TARGET_DIR Initialization**
   - Added TARGET_DIR initialization in pre-commit hook
   - Fixed references to TARGET_DIR in linting modules
   - Added proper export to make TARGET_DIR available to all modules

2. **Improved Configuration File Handling**
   - Added fallback mechanisms for missing configuration files
   - Added template-based fallback for all linting tools
   - Improved error handling when config files aren't found

3. **Enhanced Error Handling**
   - Made linting modules return success when tools aren't available
   - Prevented the pre-commit hook from failing when non-critical tools are missing
   - Improved error reporting for each linting stage

### Added Testing Scripts

1. **Individual Format Testing**
   - Added test_markdown.sh for testing Markdown linting
   - Added test_yaml.sh for testing YAML validation
   - Added test_json.sh for testing JSON validation
   - Added test_toml.sh for testing TOML validation

2. **Comprehensive Testing**
   - Added test_all_formats.sh for testing all format validators
   - Added debug_hooks.sh for diagnosing common issues

3. **Documented Testing Procedures**
   - Added scripts/README.md with usage instructions
   - Added docs/linting-features.md with comprehensive documentation

### Improved Documentation

1. **Added Linting Features Documentation**
   - Documented all supported file types
   - Described configuration file locations
   - Listed required tools and installation instructions
   - Provided troubleshooting guidance

2. **Added Fallback Behavior Documentation**
   - Explained how missing tools are handled
   - Documented configuration options
   - Added examples of common customizations

## Version 0.5.0 (2025-03-05)

### Added Documentation Linting

1. **Added Markdown Support**
   - Added core/markdown.lua module
   - Added markdown scripts for fixing common issues

2. **Added Config File Validation**
   - Added core/yaml.lua module
   - Added core/json.lua module
   - Added core/toml.lua module

### Enhanced Workflows

1. **Improved Github Actions Integration**
   - Added automatic workflow installation
   - Added support for workflow configuration templates

2. **Added Submodule Support**
   - Added post-update hooks
   - Added automatic detection of submodule updates