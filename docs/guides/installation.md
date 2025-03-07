# Installing Hooks-Util

This guide explains how to properly install hooks-util in your project, either as a direct installation or as a git submodule.

## Installation Methods

### Direct Installation (Recommended for Development)

```bash
# Clone the repository
git clone https://github.com/greggh/hooks-util.git

# Run the installation script
./hooks-util/install.sh -t /path/to/your/project
```

### Git Submodule Installation (Recommended for Production)

Adding hooks-util as a git submodule provides better version control and easier updates:

```bash
# Add as a submodule
git submodule add https://github.com/greggh/hooks-util.git .githooks/hooks-util

# Initialize and update submodules (including nested ones like lust-next)
git submodule update --init --recursive

# Run the installation script
./.githooks/hooks-util/install.sh
```

## Post-Installation Steps

### Important: Tracking Configuration Files

After installation, hooks-util creates several configuration files that should be tracked in git to ensure consistent behavior across all users of the repository:

1. The installation process now creates a tracking file at `.githooks/.hooks-util-files.txt` that lists all files created by hooks-util.

2. You should add these files to git to track them:

```bash
git add $(cat .githooks/.hooks-util-files.txt)
git commit -m "Add hooks-util configuration files"
```

3. This typically includes:
   - `.githooks/` directory with hook scripts
   - Linting configuration files (`.markdownlint.json`, `.yamllint.yml`, etc.)
   - GitHub workflow files (if applicable)

### Ensuring Proper Submodule Initialization

If you're using hooks-util as a submodule, it's important to ensure that all nested submodules (like lust-next) are properly initialized:

```bash
# Use our helper script to ensure all submodules are properly initialized
./.githooks/hooks-util/scripts/ensure_submodules.sh
```

## Troubleshooting

### Missing lust-next

If you encounter errors about missing lust-next, especially in testbed projects:

1. Ensure all submodules are properly initialized:
   ```bash
   git submodule update --init --recursive
   ```

2. Or use our helper script:
   ```bash
   ./.githooks/hooks-util/scripts/ensure_submodules.sh
   ```

### Untracked Configuration Files

If you see untracked configuration files after installation:

1. Check the tracking file:
   ```bash
   cat .githooks/.hooks-util-files.txt
   ```

2. Add all the listed files to git:
   ```bash
   git add $(cat .githooks/.hooks-util-files.txt)
   ```

## Configuration

You can customize the hooks behavior by creating a `.hooksrc` file in your project root:

```bash
# Example .hooksrc
HOOKS_STYLUA_ENABLED=true
HOOKS_LUACHECK_ENABLED=true
HOOKS_TESTS_ENABLED=true
HOOKS_TEST_QUALITY_ENABLED=true
```

For more detailed configuration options, see [Configuration Reference](../reference/configuration-options.md).