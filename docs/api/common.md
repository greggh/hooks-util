# Common Module API Reference

The common.sh module provides core utility functions and configuration handling for hooks-util.

## Configuration Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `HOOKS_VERBOSITY` | integer | 1 | Output verbosity level (0=quiet, 1=normal, 2=verbose) |
| `HOOKS_STYLUA_ENABLED` | boolean | true | Enable/disable StyLua formatting |
| `HOOKS_LUACHECK_ENABLED` | boolean | true | Enable/disable Luacheck linting |
| `HOOKS_TESTS_ENABLED` | boolean | true | Enable/disable test execution |
| `HOOKS_QUALITY_ENABLED` | boolean | true | Enable/disable code quality fixes |
| `HOOKS_TEST_TIMEOUT` | integer | 60000 | Test timeout in milliseconds |

## Output Functions

### hooks_error

Prints an error message.

```bash
hooks_error "Error message"
```

**Parameters**:
- `$1`: The error message to print

**Returns**: Nothing, writes to stderr

### hooks_warning

Prints a warning message.

```bash
hooks_warning "Warning message"
```

**Parameters**:
- `$1`: The warning message to print

**Returns**: Nothing, writes to stderr

### hooks_info

Prints an info message.

```bash
hooks_info "Info message"
```

**Parameters**:
- `$1`: The info message to print

**Returns**: Nothing, writes to stdout

### hooks_success

Prints a success message.

```bash
hooks_success "Success message"
```

**Parameters**:
- `$1`: The success message to print

**Returns**: Nothing, writes to stdout

### hooks_debug

Prints a debug message if verbosity is set to verbose.

```bash
hooks_debug "Debug message"
```

**Parameters**:
- `$1`: The debug message to print

**Returns**: Nothing, writes to stderr if `HOOKS_VERBOSITY` >= 2

### hooks_message

Prints a message if verbosity is not set to quiet.

```bash
hooks_message "Message"
```

**Parameters**:
- `$1`: The message to print

**Returns**: Nothing, writes to stdout if `HOOKS_VERBOSITY` >= 1

### hooks_print_header

Prints a section header with formatting.

```bash
hooks_print_header "Section Title"
```

**Parameters**:
- `$1`: The header text to print

**Returns**: Nothing, writes to stdout if `HOOKS_VERBOSITY` >= 1

## Utility Functions

### hooks_command_exists

Checks if a command exists in the PATH.

```bash
if hooks_command_exists "command-name"; then
  # Command exists
fi
```

**Parameters**:
- `$1`: The command name to check

**Returns**: 0 if the command exists, 1 otherwise

### hooks_set_verbosity

Sets the verbosity level for output functions.

```bash
hooks_set_verbosity 2  # Set to verbose
```

**Parameters**:
- `$1`: The verbosity level (0=quiet, 1=normal, 2=verbose)

**Returns**: Nothing, sets the `HOOKS_VERBOSITY` variable

### hooks_load_config

Loads configuration from .hooksrc files.

```bash
hooks_load_config ["/path/to/.hooksrc"]
```

**Parameters**:
- `$1` (optional): Path to the main configuration file. If not provided, defaults to ".hooksrc" in the current directory.

**Returns**: Nothing, sets configuration variables

### hooks_git_root

Gets the top level directory of the Git repository.

```bash
repo_root=$(hooks_git_root)
```

**Parameters**: None

**Returns**: The absolute path to the Git repository root

### hooks_is_lua_file

Checks if a file is a Lua file (based on file extension).

```bash
if hooks_is_lua_file "path/to/file.lua"; then
  # File is a Lua file
fi
```

**Parameters**:
- `$1`: The file path to check

**Returns**: 0 if the file is a Lua file, 1 otherwise

### hooks_get_staged_lua_files

Gets a list of all staged Lua files in the Git repository.

```bash
staged_files=$(hooks_get_staged_lua_files)
```

**Parameters**: None

**Returns**: Newline-separated list of staged Lua file paths

## Usage Example

```bash
#!/bin/bash
# Example script using common.sh

# Include the library
source "/path/to/hooks-util/lib/common.sh"

# Load configuration
hooks_load_config

# Check if a command exists
if ! hooks_command_exists "stylua"; then
  hooks_error "StyLua is not installed"
  exit 1
fi

# Print a header
hooks_print_header "Processing Files"

# Get staged Lua files
staged_files=$(hooks_get_staged_lua_files)

# Process each file
while IFS= read -r file; do
  if [ -n "$file" ]; then
    hooks_info "Processing $file"
    # Do something with the file
    if [ $? -eq 0 ]; then
      hooks_success "Successfully processed $file"
    else
      hooks_error "Failed to process $file"
    fi
  fi
done <<< "$staged_files"
```