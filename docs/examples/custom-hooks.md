# Creating Custom Hooks

This guide demonstrates how to create custom Git hooks using the hooks-util library.

## Why Create Custom Hooks?

While the standard pre-commit hook provided by hooks-util is powerful, you might need custom functionality:

- Project-specific validation
- Special build steps before commits
- Custom workflows for your team
- Integrations with other tools

## Example: Custom Pre-Push Hook

Let's create a custom pre-push hook that ensures all tests pass before pushing to a remote repository.

### Step 1: Create the Hook File

Create a file at `.git/hooks/pre-push`:

```bash
#!/bin/bash
# Custom pre-push hook using hooks-util
set -eo pipefail  # Exit on error, error on pipeline failures

# Determine the hooks-util location
HOOKS_UTIL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.hooks-util" && pwd)"

# Include library files
source "${HOOKS_UTIL_DIR}/lib/common.sh"
source "${HOOKS_UTIL_DIR}/lib/error.sh"
source "${HOOKS_UTIL_DIR}/lib/path.sh"
source "${HOOKS_UTIL_DIR}/lib/test.sh"

# Print banner
hooks_print_header "Custom Pre-Push Hook"
hooks_debug "Running from: $(pwd)"

# Load configuration
hooks_load_config

# Get the top level of the git repository
TOP_LEVEL=$(hooks_git_root)
cd "$TOP_LEVEL" || exit 1

# Check branch - only run on main or specific branches
current_branch=$(git symbolic-ref --short HEAD)
protected_branches=("main" "develop" "release")

if [[ " ${protected_branches[*]} " == *" $current_branch "* ]]; then
  hooks_info "Pushing to protected branch: $current_branch"
  
  # Run comprehensive tests before pushing
  hooks_run_tests "$TOP_LEVEL"
  hooks_handle_error $? "Tests failed, cannot push to $current_branch"
  
  # Additional custom checks could go here
  # ...
else
  hooks_info "Pushing to non-protected branch: $current_branch"
  # Maybe run a lighter version of tests
fi

# Print error summary and exit with appropriate code
hooks_print_error_summary
exit $?
```

### Step 2: Make the Hook Executable

```bash
chmod +x .git/hooks/pre-push
```

### Example: Custom Post-Checkout Hook

Let's create a post-checkout hook that sets up the environment when switching branches.

### Step 1: Create the Hook File

Create a file at `.git/hooks/post-checkout`:

```bash
#!/bin/bash
# Custom post-checkout hook using hooks-util
set -eo pipefail  # Exit on error, error on pipeline failures

# Determine the hooks-util location
HOOKS_UTIL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.hooks-util" && pwd)"

# Include library files
source "${HOOKS_UTIL_DIR}/lib/common.sh"
source "${HOOKS_UTIL_DIR}/lib/error.sh"
source "${HOOKS_UTIL_DIR}/lib/path.sh"

# Print banner
hooks_print_header "Custom Post-Checkout Hook"

# Get arguments passed to the hook
prev_head="$1"
new_head="$2"
checkout_type="$3"  # 1 = branch checkout, 0 = file checkout

# Only run for branch checkouts
if [ "$checkout_type" -eq 1 ]; then
  # Get current branch name
  current_branch=$(git symbolic-ref --short HEAD)
  hooks_info "Switched to branch: $current_branch"
  
  # Check for dependency files
  if [ -f "package.json" ]; then
    hooks_info "Checking for new npm dependencies..."
    if ! diff <(git show "$prev_head:package.json" 2>/dev/null | grep -Eo '"dependencies"|"devDependencies"') \
            <(cat package.json | grep -Eo '"dependencies"|"devDependencies"') &>/dev/null; then
      hooks_warning "Dependencies may have changed. Consider running: npm install"
    fi
  fi
  
  # Check if we're on a feature branch
  if [[ "$current_branch" == feature/* ]]; then
    # Custom setup for feature branches
    hooks_info "Setting up feature branch environment..."
    # Add custom logic here
  fi
fi

exit 0
```

### Step 2: Make the Hook Executable

```bash
chmod +x .git/hooks/post-checkout
```

## Best Practices for Custom Hooks

1. **Keep hooks focused** - Each hook should have a clear purpose
2. **Handle errors gracefully** - Use `hooks_handle_error` for consistent error handling
3. **Be informative** - Use `hooks_info`, `hooks_warning`, and `hooks_error` for clear messages
4. **Respect configuration** - Use `hooks_load_config` to read user settings
5. **Keep it fast** - Optimize performance, especially for pre-commit hooks
6. **Provide escape hatches** - Allow bypassing in emergency situations (with warnings)

## Advanced: Sharing Custom Hooks

To share custom hooks with your team:

1. Create a `.githooks` directory in your repository
2. Add your custom hook scripts there
3. Update your `.hooksrc` to include a setup step:

```bash
# In .hooksrc
HOOKS_CUSTOM_HOOKS_DIR=".githooks"
```

Then modify the install.sh script to copy these hooks to .git/hooks when installing.
