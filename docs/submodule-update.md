
# Submodule Update Mechanism

This document explains how the hooks-util submodule update mechanism works and how to use it in your projects.

## Overview

When hooks-util is included as a git submodule in your project, you need a way to ensure that hooks are updated automatically when the submodule is updated. Git doesn't provide a built-in hook specifically for submodule updates, so hooks-util implements a custom solution.

## How It Works

The hooks-util installation script sets up three key components:

1. **post-merge hook**: Runs after git merge/pull operations in the parent repository
2. **post-checkout hook**: Runs after git checkout operations in the parent repository
3. **post-submodule-update hook**: A custom hook that runs after git submodule update operations

The first two hooks are standard Git hooks, but the third one is custom and requires additional setup to work.

## Setting Up Submodule Update Hook

To enable the automatic submodule update hook, you need to add a wrapper around the git command. The hooks-util project includes a `gitmodules-hooks.sh` script that defines this wrapper.

### Steps to Enable

1. Add these lines to your shell configuration file (e.g., `~/.bashrc` or `~/.zshrc`):

   ```bash
   source "/path/to/your/repo/hooks-util/scripts/gitmodules-hooks.sh"
   alias git=git_with_hooks
   ```

2. Replace `/path/to/your/repo` with the actual path to your repository.

3. Reload your shell configuration:

   ```bash
   source ~/.bashrc  # Or source ~/.zshrc for Zsh users
   ```

## How to Test

After setting up the wrapper, you can test that the mechanism works:

1. Update the hooks-util submodule:

   ```bash
   git submodule update --remote hooks-util
   ```

2. You should see output indicating that the post-submodule-update hook is running.

3. The hook will automatically check if hooks-util has been updated and reinstall hooks if needed.

## Alternative Approach

If you prefer not to modify your shell configuration, you can still ensure hooks stay updated by:

1. Running the hooks-util installation script manually after updating the submodule:

   ```bash
   git submodule update --remote hooks-util
   ./hooks-util/install.sh
   ```

2. Creating a git alias that combines these steps:

   ```bash
   git config --global alias.update-hooks '!f() { git submodule update --remote hooks-util && ./hooks-util/install.sh; }; f'
   ```

   Then you can use `git update-hooks` to update the hooks-util submodule and reinstall hooks in one step.

## Troubleshooting

- **Hook not running after submodule update**: Make sure you've properly set up the git wrapper in your shell configuration.
- **Permission denied errors**: Check that the hook scripts are executable (`chmod +x .githooks/post-submodule-update`).
- **Hooks not being updated**: Try running with the --force flag: `./hooks-util/install.sh --force`.

## Further Reading

- [Git Hooks Documentation](https://git-scm.com/docs/githooks)
- [Git Submodules Documentation](https://git-scm.com/book/en/v2/Git-Tools-Submodules)

