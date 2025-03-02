# Error Codes Reference

This document lists all error codes used in the hooks-util library, their meanings, and how to resolve them.

## General Error Codes

| Code | Constant | Description | Solution |
|------|----------|-------------|----------|
| 0 | `HOOKS_ERROR_SUCCESS` | Operation completed successfully | No action needed |
| 1 | `HOOKS_ERROR_GENERAL` | General error occurred | Check the error message for details |
| 127 | `HOOKS_ERROR_COMMAND_NOT_FOUND` | Required command not found | Install the missing command or specify its path in configuration |

## Tool-Specific Error Codes

| Code | Constant | Description | Solution |
|------|----------|-------------|----------|
| 10 | `HOOKS_ERROR_STYLUA_FAILED` | StyLua formatting failed | Check StyLua output for syntax errors or configuration issues |
| 11 | `HOOKS_ERROR_LUACHECK_FAILED` | Luacheck validation failed | Fix the reported linting errors |
| 12 | `HOOKS_ERROR_TESTS_FAILED` | Tests failed | Debug the failing tests |

## Configuration and System Error Codes

| Code | Constant | Description | Solution |
|------|----------|-------------|----------|
| 20 | `HOOKS_ERROR_CONFIG_INVALID` | Configuration error | Check your .hooksrc file for syntax errors |
| 30 | `HOOKS_ERROR_PATH_NOT_FOUND` | Path not found | Verify file paths in your configuration |
| 40 | `HOOKS_ERROR_TIMEOUT` | Operation timed out | Increase timeout in configuration or optimize the operation |

## Handling Errors

### In Hooks

When an error occurs in a hook, the hook typically:

1. Prints a descriptive error message using `hooks_error()`
2. Records the error for the summary with `hooks_handle_error()`
3. Continues with other checks if possible
4. Displays an error summary at the end with `hooks_print_error_summary()`
5. Returns the appropriate error code

### In Custom Scripts

When using hooks-util in custom scripts, you should handle errors like this:

```bash
# Call a hooks-util function
hooks_stylua_format "my_file.lua"
exit_code=$?

# Handle the error
if [ $exit_code -ne 0 ]; then
  # Use hooks_handle_error to properly record the error
  hooks_handle_error $exit_code "StyLua formatting failed for my_file.lua"
  
  # Decide whether to continue or exit
  if [ $exit_code -eq $HOOKS_ERROR_COMMAND_NOT_FOUND ]; then
    hooks_warning "Continuing without StyLua"
  else
    # Print summary and exit
    hooks_print_error_summary
    exit $exit_code
  fi
fi
```

## Bypassing Hooks on Error

In emergency situations, you can bypass pre-commit hooks using:

```bash
git commit --no-verify -m "Emergency commit message"
```

This will skip all pre-commit hooks, but should only be used in exceptional circumstances.

## Common Error Scenarios

### StyLua Not Found

```
Error: StyLua is not installed. Please install it to format Lua code.
You can install it from: https://github.com/JohnnyMorganz/StyLua
```

**Solution**: Install StyLua or specify its path in your configuration:

```bash
# In .hooksrc.local
HOOKS_STYLUA_PATH=/path/to/stylua
```

### Luacheck Not Found

```
Error: Luacheck is not installed. Please install it to lint Lua code.
You can install it via LuaRocks: luarocks install luacheck
```

**Solution**: Install Luacheck or specify its path in your configuration:

```bash
# In .hooksrc.local
HOOKS_LUACHECK_PATH=/path/to/luacheck
```

### Test Framework Not Detected

```
Error: Unknown or unsupported test framework
```

**Solution**: Set up a proper test framework (Plenary or Makefile) or disable tests:

```bash
# In .hooksrc or .hooksrc.user
HOOKS_TESTS_ENABLED=false
```