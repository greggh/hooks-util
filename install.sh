#!/bin/bash
# Installation script for Neovim Hooks Utilities

set -e

# Determine the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Include library files 
LIB_DIR="${SCRIPT_DIR}/lib"
source "${LIB_DIR}/common.sh"
source "${LIB_DIR}/error.sh"
source "${LIB_DIR}/path.sh"

# Print banner
hooks_print_header "Neovim Hooks Utilities Installation v${HOOKS_UTIL_VERSION}"

# Function to display usage information
show_usage() {
  echo "Usage: $0 [OPTIONS]"
  echo
  echo "Options:"
  echo "  -t, --target DIR  Install hooks to target directory (default: current git repo)"
  echo "  -c, --config      Create a default .hooksrc configuration file"
  echo "  -f, --force       Overwrite existing hooks"
  echo "  -v, --verbose     Enable verbose output"
  echo "  --dry-run         Show what would be done without making changes"
  echo "  -h, --help        Show this help message"
  echo
  echo "Examples:"
  echo "  $0                    Install to current git repository"
  echo "  $0 -t /path/to/repo   Install to specified repository"
  echo "  $0 -c -v              Install with config file and verbose output"
  echo "  $0 --dry-run          Test the installation process without making changes"
}

# Parse command line arguments
TARGET_DIR=""
CREATE_CONFIG=false
FORCE_OVERWRITE=false
DRY_RUN=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    -t|--target)
      TARGET_DIR="$2"
      shift 2
      ;;
    -c|--config)
      CREATE_CONFIG=true
      shift
      ;;
    -f|--force)
      FORCE_OVERWRITE=true
      shift
      ;;
    -v|--verbose)
      hooks_set_verbosity "$HOOKS_VERBOSITY_VERBOSE"
      shift
      ;;
    --dry-run)
      DRY_RUN=true
      hooks_info "Running in dry-run mode (no changes will be made)"
      shift
      ;;
    -h|--help)
      show_usage
      exit 0
      ;;
    *)
      hooks_error "Unknown option: $1"
      show_usage
      exit 1
      ;;
  esac
done

# Determine target directory (current git repo if not specified)
if [ -z "$TARGET_DIR" ]; then
  if ! TARGET_DIR=$(hooks_git_root); then
    hooks_error "Not in a git repository. Please specify a target directory with -t."
    exit 1
  fi
fi

hooks_info "Installing to: $TARGET_DIR"

# Ensure the target directory exists and is a git repository
if [ ! -d "$TARGET_DIR/.git" ]; then
  hooks_error "Target directory is not a git repository: $TARGET_DIR"
  exit 1
fi

# Create .githooks directory in the target repository
HOOKS_DIR="$TARGET_DIR/.githooks"
if [ "$DRY_RUN" = false ]; then
  mkdir -p "$HOOKS_DIR"
  hooks_info "Created hooks directory: $HOOKS_DIR"
else
  hooks_info "[DRY RUN] Would create hooks directory: $HOOKS_DIR"
fi

# Copy hook files
hooks_print_header "Installing hooks"
for hook_file in "$SCRIPT_DIR/hooks"/*; do
  if [ -f "$hook_file" ]; then
    hook_name=$(basename "$hook_file")
    target_file="$HOOKS_DIR/$hook_name"
    
    # Check if the hook already exists
    if [ -f "$target_file" ] && [ "$FORCE_OVERWRITE" = false ]; then
      hooks_warning "Hook already exists: $target_file"
      hooks_warning "Use -f to overwrite existing hooks"
      continue
    fi
    
    # Copy the hook file
    if [ "$DRY_RUN" = false ]; then
      cp "$hook_file" "$target_file"
      chmod +x "$target_file"
      hooks_success "Installed hook: $hook_name"
    else
      hooks_info "[DRY RUN] Would install hook: $hook_name"
    fi
  fi
done

# Create symbolic links to lib directory
LIB_TARGET_DIR="$HOOKS_DIR/lib"
if [ -d "$LIB_TARGET_DIR" ] && [ "$FORCE_OVERWRITE" = false ]; then
  hooks_warning "Lib directory already exists: $LIB_TARGET_DIR"
else
  if [ "$DRY_RUN" = false ]; then
    # Remove existing lib directory if it exists
    rm -rf "$LIB_TARGET_DIR"
    
    # Create lib directory
    mkdir -p "$LIB_TARGET_DIR"
    
    # Copy lib files
    for lib_file in "$SCRIPT_DIR/lib"/*.sh; do
      if [ -f "$lib_file" ]; then
        cp "$lib_file" "$LIB_TARGET_DIR/"
      fi
    done
    
    hooks_success "Installed library files to: $LIB_TARGET_DIR"
  else
    hooks_info "[DRY RUN] Would install library files to: $LIB_TARGET_DIR"
  fi
fi

# Set up Git hooks directory
hooks_print_header "Configuring Git"
pushd "$TARGET_DIR" > /dev/null
if [ "$DRY_RUN" = false ]; then
  git config core.hooksPath .githooks
  hooks_success "Configured Git to use hooks from: .githooks"
else
  hooks_info "[DRY RUN] Would configure Git to use hooks from: .githooks"
fi
popd > /dev/null

# Create configuration files if requested
if [ "$CREATE_CONFIG" = true ]; then
  # Main configuration
  CONFIG_FILE="$TARGET_DIR/.hooksrc"
  if [ -f "$CONFIG_FILE" ] && [ "$FORCE_OVERWRITE" = false ]; then
    hooks_warning "Configuration file already exists: $CONFIG_FILE"
  else
    if [ "$DRY_RUN" = false ]; then
      cp "$SCRIPT_DIR/templates/hooksrc.template" "$CONFIG_FILE"
      hooks_success "Created main configuration file: $CONFIG_FILE"
    else
      hooks_info "[DRY RUN] Would create main configuration file: $CONFIG_FILE"
    fi
  fi
  
  # Example local configuration
  LOCAL_CONFIG_EXAMPLE="$TARGET_DIR/.hooksrc.local.example"
  if [ -f "$LOCAL_CONFIG_EXAMPLE" ] && [ "$FORCE_OVERWRITE" = false ]; then
    hooks_warning "Local configuration example already exists: $LOCAL_CONFIG_EXAMPLE"
  else
    if [ "$DRY_RUN" = false ]; then
      if [ -f "$SCRIPT_DIR/.hooksrc.local.example" ]; then
        cp "$SCRIPT_DIR/.hooksrc.local.example" "$LOCAL_CONFIG_EXAMPLE"
        hooks_success "Created local configuration example: $LOCAL_CONFIG_EXAMPLE"
      else
        # Fallback to template if example doesn't exist
        cp "$SCRIPT_DIR/templates/hooksrc.template" "$LOCAL_CONFIG_EXAMPLE"
        hooks_success "Created local configuration example (from template): $LOCAL_CONFIG_EXAMPLE"
      fi
    else
      hooks_info "[DRY RUN] Would create local configuration example: $LOCAL_CONFIG_EXAMPLE"
    fi
  fi
  
  # Example user configuration
  USER_CONFIG_EXAMPLE="$TARGET_DIR/.hooksrc.user.example"
  if [ -f "$USER_CONFIG_EXAMPLE" ] && [ "$FORCE_OVERWRITE" = false ]; then
    hooks_warning "User configuration example already exists: $USER_CONFIG_EXAMPLE"
  else
    if [ "$DRY_RUN" = false ]; then
      if [ -f "$SCRIPT_DIR/.hooksrc.user.example" ]; then
        cp "$SCRIPT_DIR/.hooksrc.user.example" "$USER_CONFIG_EXAMPLE"
        hooks_success "Created user configuration example: $USER_CONFIG_EXAMPLE"
      else
        # Fallback to template if example doesn't exist
        cp "$SCRIPT_DIR/templates/hooksrc.template" "$USER_CONFIG_EXAMPLE"
        hooks_success "Created user configuration example (from template): $USER_CONFIG_EXAMPLE"
      fi
    else
      hooks_info "[DRY RUN] Would create user configuration example: $USER_CONFIG_EXAMPLE"
    fi
  fi
  
  hooks_info "To use advanced configuration:"
  hooks_info "  cp .hooksrc.local.example .hooksrc.local"
  hooks_info "  cp .hooksrc.user.example .hooksrc.user"
fi

hooks_print_header "Installation complete"
hooks_success "Hooks are ready to use!"
hooks_info "Pre-commit hook will:"
hooks_info "- Format Lua files using StyLua"
hooks_info "- Run Luacheck for Lua code linting"
hooks_info "- Run ShellCheck for shell script validation"
hooks_info "- Fix common issues automatically:"
hooks_info "  - Trailing whitespace"
hooks_info "  - Line endings"
hooks_info "  - Prefix unused variables with _"
hooks_info "  - Add final newlines to files"
hooks_info "- Run tests to ensure code quality"
hooks_info ""
hooks_info "To customize, edit: $TARGET_DIR/.hooksrc"

exit 0