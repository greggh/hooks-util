# Neovim Hooks Utilities Documentation

This directory contains extended documentation for the Neovim Hooks Utilities project. Here you'll find detailed guides, configuration references, API documentation, and examples.

## Planned Documentation

As the project expands, we plan to add:

- **Hook API Reference**: Details on all hook functions and their parameters
- **Configuration Guide**: Comprehensive configuration options with examples
- **Advanced Usage**: Custom hook development and integration scenarios
- **Troubleshooting Guide**: Common issues and solutions
- **Plugin Integrations**: How to integrate with other Neovim plugins

## Documentation Structure

```
docs/
├── api/              # API reference for hook functions
├── guides/           # How-to guides for specific use cases
├── examples/         # Example configurations and implementations
└── reference/        # Technical reference for configuration options
```

## Best Practices for Git Hooks

When working with the Neovim Hooks Utilities:

1. **Keep hooks focused** - Each hook should have a single responsibility
2. **Fail gracefully** - Hooks should handle errors and provide useful messages
3. **Respect user configuration** - Hooks should be customizable and respect user preferences
4. **Document behavior** - Hooks should have clear documentation on what they do
5. **Performance matters** - Hooks should be optimized for speed, especially pre-commit hooks

## Writing Your Own Hooks

To create custom hooks based on the Neovim Hooks Utilities library:

1. Create a new script in your project's `.githooks` directory
2. Source the necessary library files from the hooks-util installation
3. Use the provided utility functions for error handling, path normalization, etc.
4. Test your hook thoroughly in different environments

Example of a custom hook:

```bash
#!/bin/bash
# Custom pre-push hook

# Source the hooks-util libraries
source .hooks-util/lib/common.sh
source .hooks-util/lib/error.sh

# Your custom hook implementation
hooks_print_header "Running custom pre-push hook"

# Use the hooks-util functions for consistent behavior
if ! hooks_command_exists "command-to-check"; then
  hooks_error "Required command is missing"
  exit 1
fi

# Success message
hooks_success "Pre-push checks passed!"
```
