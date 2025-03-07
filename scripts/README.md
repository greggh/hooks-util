
# Hooks-Util Testing Scripts

This directory contains scripts for testing, debugging, and maintaining the hooks-util framework.

## Debugging Scripts

- `debug_hooks.sh`: General-purpose debugging script that checks tool availability, configuration loading, and library paths
  - Usage: `./scripts/debug_hooks.sh`

## Individual Format Testing Scripts

These scripts test the linting and validation functionality for specific file formats:

- `test_markdown.sh`: Tests Markdown linting and fixing
  - Usage: `./scripts/test_markdown.sh`

- `test_yaml.sh`: Tests YAML validation
  - Usage: `./scripts/test_yaml.sh`

- `test_json.sh`: Tests JSON validation
  - Usage: `./scripts/test_json.sh`

- `test_toml.sh`: Tests TOML validation
  - Usage: `./scripts/test_toml.sh`

## Comprehensive Testing

- `test_all_formats.sh`: Tests all format validators in a single run
  - Usage: `./scripts/test_all_formats.sh`

## Maintenance Scripts

- `cleanup_backups.sh`: Cleans up backup files created during hooks-util installation
  - Usage: `./scripts/cleanup_backups.sh [target_directory]`
  - Example: `./scripts/cleanup_backups.sh /path/to/your/project`
  - Note: If no directory is specified, it defaults to the current directory

## Running the Tests

To run these tests:

1. Change to the hooks-util root directory
2. Run the desired test script

Example:

```bash
env -C /home/gregg/Projects/lua-library/hooks-util ./scripts/test_all_formats.sh

```text

## Required Tools

For complete testing, the following tools should be installed:

- Markdown: `markdownlint` or `markdownlint-cli`
- YAML: `yamllint`
- JSON: `jsonlint` or `jq`
- TOML: `tomlcheck` or `taplo`

If a tool is not found, the tests will warn but continue execution.

## Test Project Integration

To test with hooks-util testbed projects:

1. Install hooks-util in the testbed:
   ```bash
   env -C /path/to/testbed /home/gregg/Projects/lua-library/hooks-util/install.sh
   ```

2. Run the debug script in the testbed:
   ```bash
   env -C /path/to/testbed /home/gregg/Projects/lua-library/hooks-util/scripts/debug_hooks.sh
   ```

3. Try creating and committing files of different formats to test the pre-commit hook.

## Troubleshooting

If you encounter issues:

1. Check if the required tools are installed
2. Verify that the configuration files (.yamllint.yml, etc.) exist or are being properly found
3. Make sure TARGET_DIR is properly set
4. Run scripts with increased verbosity (HOOKS_VERBOSITY=2)

