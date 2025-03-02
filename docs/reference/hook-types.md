# Git Hook Types Reference

This document describes the different Git hook types supported by hooks-util, including what they do and when they run.

## Implemented Hooks

### pre-commit

**When it runs**: Before a commit is created, after staging files but before creating the commit.

**What it does**:
- Fixes code quality issues in staged files (whitespace, line endings, etc.)
- Formats Lua code with StyLua
- Lints Lua code with Luacheck
- Runs tests to ensure nothing is broken

**Configuration**:
```bash
HOOKS_STYLUA_ENABLED=true    # Enable/disable StyLua formatting
HOOKS_LUACHECK_ENABLED=true  # Enable/disable Luacheck linting
HOOKS_TESTS_ENABLED=true     # Enable/disable running tests
HOOKS_QUALITY_ENABLED=true   # Enable/disable code quality fixes
```

**How to bypass**: `git commit --no-verify`

**Path**: `.git/hooks/pre-commit`

## Planned Hooks

### pre-push

**When it runs**: Before pushing commits to a remote repository.

**What it will do**:
- Run comprehensive tests
- Verify branch naming conventions
- Check for sensitive information
- Validate commit messages
- Run security scans

**Configuration** (planned):
```bash
HOOKS_PUSH_TESTS_ENABLED=true           # Run tests before pushing
HOOKS_PROTECTED_BRANCHES="main,develop" # Branches with additional checks
HOOKS_SECURITY_SCAN_ENABLED=true        # Enable security scanning
```

**Path**: `.git/hooks/pre-push`

### post-checkout

**When it runs**: After checking out a branch or file.

**What it will do**:
- Detect changes in dependency files
- Set up environment based on branch type
- Clear caches when needed
- Auto-generate configuration based on branch

**Configuration** (planned):
```bash
HOOKS_CHECKOUT_DEPS_CHECK=true           # Check for dependency changes
HOOKS_CHECKOUT_ENV_SETUP=true            # Set up environment variables
HOOKS_CHECKOUT_BRANCH_CONFIG="config.sh" # Branch-specific config
```

**Path**: `.git/hooks/post-checkout`

### post-merge

**When it runs**: After a `git merge` or `git pull` that results in a merge.

**What it will do**:
- Detect changes in dependency files
- Rebuild components when necessary
- Notify about changes in important files

**Configuration** (planned):
```bash
HOOKS_MERGE_DEPS_CHECK=true     # Check for dependency changes
HOOKS_MERGE_REBUILD=true        # Rebuild after merges
HOOKS_MERGE_NOTIFY_FILES="README.md,CONTRIBUTING.md"  # Files to notify about
```

**Path**: `.git/hooks/post-merge`

## Using Hooks

### Enabling Hooks

All hooks are installed by the `install.sh` script. You can selectively enable or disable them in your `.hooksrc` configuration file.

### Creating Custom Hooks

You can create custom versions of any hook by:

1. Creating a file with the hook name in `.git/hooks/`
2. Making it executable (`chmod +x .git/hooks/hook-name`)
3. Using the hooks-util library in your custom hook

Example of a custom hook:

```bash
#!/bin/bash
# Custom hook example
set -eo pipefail

# Include hooks-util libraries
HOOKS_UTIL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.hooks-util" && pwd)"
source "${HOOKS_UTIL_DIR}/lib/common.sh"
source "${HOOKS_UTIL_DIR}/lib/error.sh"

# Your custom logic here
hooks_print_header "Custom Hook"
# ...

exit 0
```

### Hook Arguments

Different Git hooks receive different arguments:

- **pre-commit**: No arguments
- **pre-push**: Two arguments (remote name, remote URL)
- **post-checkout**: Three arguments (previous HEAD, new HEAD, branch flag)
- **post-merge**: One argument (squash flag)

For more details, see the [Git documentation on hooks](https://git-scm.com/docs/githooks).