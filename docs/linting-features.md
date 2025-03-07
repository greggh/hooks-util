
# Hooks-Util Linting Features

## Supported File Types

Hooks-util v0.6.0 now includes comprehensive linting and validation for the following file types:

1. **Lua** - via StyLua and Luacheck
2. **Markdown** - via markdownlint or markdownlint-cli
3. **YAML** - via yamllint
4. **JSON** - via jsonlint or jq
5. **TOML** - via tomlcheck or taplo
6. **Shell Scripts** - via shellcheck

## Configuration Files

Hooks-util supports the following configuration files:

| File Type | Config File        | Template Location                   |
|-----------|-------------------|-----------------------------------|
| Lua       | .luacheckrc       | hooks-util/templates/.luacheckrc   |
| Lua       | stylua.toml       | hooks-util/templates/stylua.toml   |
| Markdown  | .markdownlint.json| hooks-util/templates/.markdownlint.json |
| YAML      | .yamllint.yml     | hooks-util/templates/.yamllint.yml |
| JSON      | .jsonlintrc       | hooks-util/templates/.jsonlintrc   |
| TOML      | .taplo.toml       | hooks-util/templates/.taplo.toml   |

## Required Tools

To leverage all linting features, the following tools should be installed:

```bash

# Lua
luarocks install luacheck
cargo install stylua

# Markdown
npm install -g markdownlint-cli

# YAML
pip install yamllint

# JSON
npm install -g jsonlint

# TOML
cargo install taplo-cli
pip install tomlcheck

# Shell
apt-get install shellcheck  # or equivalent for your system

```text

## Automatic Fixes

The hooks-util framework can automatically fix common issues:

1. **Markdown**
   - Fix list numbering
   - Fix code blocks
   - Fix heading levels
   - Fix newline issues

2. **Lua**
   - Consistent formatting via StyLua
   - Fix trailing whitespace
   - Add final newlines
   - Prefix unused variables with _

## Fallback Behavior

When a linting tool is not available:

1. The hook will display a warning but continue execution
2. It will attempt to use alternative tools when available (e.g., jq instead of jsonlint)
3. The missing tool will be reported in the pre-commit output

## Configuration Options

You can customize linting behavior in your `.hooksrc` file:

```bash

# Enable/disable specific linting tools
HOOKS_STYLUA_ENABLED=true
HOOKS_LUACHECK_ENABLED=true
HOOKS_QUALITY_ENABLED=true

# Enable/disable tests
HOOKS_TESTS_ENABLED=true
HOOKS_TEST_QUALITY_ENABLED=true

# Set verbosity level (0=quiet, 1=normal, 2=verbose)
HOOKS_VERBOSITY=1

```text

## Testing Your Setup

Use the provided testing scripts to verify your configuration:

```bash

# Test all format validators
env -C /home/gregg/Projects/lua-library/hooks-util ./scripts/test_all_formats.sh

# Test individual formats
env -C /home/gregg/Projects/lua-library/hooks-util ./scripts/test_markdown.sh
env -C /home/gregg/Projects/lua-library/hooks-util ./scripts/test_yaml.sh
env -C /home/gregg/Projects/lua-library/hooks-util ./scripts/test_json.sh
env -C /home/gregg/Projects/lua-library/hooks-util ./scripts/test_toml.sh

```text

## Troubleshooting

If you encounter issues with the linting tools:

1. Run the debug script to check tool availability and configuration:
   ```bash
   env -C /your/project/path /path/to/hooks-util/scripts/debug_hooks.sh
   ```

2. Verify that configuration files exist in your project root or in the templates directory

3. Check that the TARGET_DIR is properly set in the pre-commit hook

4. Run with increased verbosity by setting `HOOKS_VERBOSITY=2` in your `.hooksrc` file

## Managing Backup Files

The hooks-util installation process creates backup files when updating existing files. To clean up these backup files:

1. The latest version of hooks-util adds patterns to .gitignore to prevent backup files from being committed.

2. To clean up backup files in your project, use the provided cleanup script:
   ```bash
   env -C /your/project/path /path/to/hooks-util/scripts/cleanup_backups.sh
   ```

3. The script will show you how many backup files were found and ask for confirmation before removing them.

4. After installation, run the cleanup script to keep your project directory clean.

