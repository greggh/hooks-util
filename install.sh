#!/bin/bash
# Installation script for Neovim Hooks Utilities

set -e

# Determine the directory where this script is located
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Include library files 
LIB_DIR="${ROOT_DIR}/lib"
source "${LIB_DIR}/common.sh"
source "${LIB_DIR}/error.sh"
source "${LIB_DIR}/path.sh"

# Make sure we preserve the root directory path
SCRIPT_DIR="$ROOT_DIR"

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
  echo "  -q, --quiet       Reduce output verbosity"
  echo "  --dry-run         Show what would be done without making changes"
  echo "  --check-updates-only Check for updates without installing new files"
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
CHECK_UPDATES_ONLY=false

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
    -q|--quiet)
      hooks_set_verbosity "$HOOKS_VERBOSITY_QUIET"
      shift
      ;;
    --dry-run)
      DRY_RUN=true
      hooks_info "Running in dry-run mode (no changes will be made)"
      shift
      ;;
    --check-updates-only)
      CHECK_UPDATES_ONLY=true
      hooks_info "Running in check-updates-only mode (only checking for updates)"
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
    
    # Check if the hook file needs updating
    HOOK_NEEDS_UPDATE=false
    
    if [ -f "$target_file" ]; then
      if [ "$FORCE_OVERWRITE" = true ] || [ "$NEED_UPDATE" = true ]; then
        HOOK_NEEDS_UPDATE=true
      else
        # Check if source and target are different
        if ! cmp -s "$hook_file" "$target_file"; then
          HOOK_NEEDS_UPDATE=true
          hooks_info "Hook file $hook_name has changed and needs updating"
        fi
      fi
    else
      # Hook doesn't exist yet
      HOOK_NEEDS_UPDATE=true
    fi
    
    # Install or update the hook file
    if [ "$HOOK_NEEDS_UPDATE" = true ]; then
      if [ "$DRY_RUN" = false ] && [ "$CHECK_UPDATES_ONLY" = false ]; then
        # Backup existing hook if it exists
        if [ -f "$target_file" ]; then
          backup_file="${target_file}.backup.$(date +%Y%m%d%H%M%S)"
          cp "$target_file" "$backup_file"
          hooks_info "Backed up existing hook to: $backup_file"
        fi
        
        cp "$hook_file" "$target_file"
        chmod +x "$target_file"
        hooks_success "Installed hook: $hook_name"
      elif [ "$CHECK_UPDATES_ONLY" = true ]; then
        hooks_info "Update needed for hook: $hook_name"
      else
        hooks_info "[DRY RUN] Would install hook: $hook_name"
      fi
    else
      hooks_info "Hook $hook_name is up to date"
    fi
  fi
done

# Handle library files directory
LIB_TARGET_DIR="$HOOKS_DIR/lib"
NEED_UPDATE=false

# Check if an update is needed
if [ -d "$LIB_TARGET_DIR" ]; then
  # Check if version file exists in target
  if [ -f "$LIB_TARGET_DIR/version.sh" ]; then
    # Source the installed version file to compare
    # Save current version
    CURRENT_VERSION=$HOOKS_UTIL_VERSION
    
    # Source installed version (will override HOOKS_UTIL_VERSION)
    # shellcheck disable=SC1090
    source "$LIB_TARGET_DIR/version.sh"
    INSTALLED_VERSION=$HOOKS_UTIL_VERSION
    
    # Restore current version
    HOOKS_UTIL_VERSION=$CURRENT_VERSION
    
    hooks_info "Installed hooks-util version: $INSTALLED_VERSION, Current version: $HOOKS_UTIL_VERSION"
    
    # Compare versions
    if [ "$INSTALLED_VERSION" != "$HOOKS_UTIL_VERSION" ]; then
      hooks_info "Version mismatch detected - update needed"
      NEED_UPDATE=true
    fi
    
    # Check for required files (v0.6.0+)
    for req_file in markdown.sh yaml.sh json.sh toml.sh; do
      if [ ! -f "$LIB_TARGET_DIR/$req_file" ]; then
        hooks_info "Missing required file $req_file - update needed"
        NEED_UPDATE=true
        break
      fi
    done
  else
    # No version file means old installation, update needed
    hooks_info "No version information found - update needed"
    NEED_UPDATE=true
  fi
  
  # Force update if requested
  if [ "$FORCE_OVERWRITE" = true ]; then
    NEED_UPDATE=true
  fi
fi

# Install or update lib files
if [ ! -d "$LIB_TARGET_DIR" ] || [ "$NEED_UPDATE" = true ]; then
  if [ "$DRY_RUN" = false ] && [ "$CHECK_UPDATES_ONLY" = false ]; then
    # Backup existing directory if it exists
    if [ -d "$LIB_TARGET_DIR" ]; then
      BACKUP_DIR="${LIB_TARGET_DIR}.backup.$(date +%Y%m%d%H%M%S)"
      mv "$LIB_TARGET_DIR" "$BACKUP_DIR"
      hooks_info "Backed up existing lib directory to: $BACKUP_DIR"
    fi
    
    # Create lib directory
    mkdir -p "$LIB_TARGET_DIR"
    
    # Copy lib files
    for lib_file in "$SCRIPT_DIR/lib"/*.sh; do
      if [ -f "$lib_file" ]; then
        cp "$lib_file" "$LIB_TARGET_DIR/"
        # Make sure all library files are executable
        chmod +x "$LIB_TARGET_DIR/$(basename "$lib_file")"
      fi
    done
    
    hooks_success "Installed/updated library files to: $LIB_TARGET_DIR"
  elif [ "$CHECK_UPDATES_ONLY" = true ]; then
    hooks_info "Update needed for library files (version $HOOKS_UTIL_VERSION)"
  else
    hooks_info "[DRY RUN] Would install/update library files to: $LIB_TARGET_DIR"
  fi
else
  hooks_info "Library files are up to date (version $HOOKS_UTIL_VERSION)"
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

# Install documentation linting tools (markdown, yaml, json, toml)
hooks_print_header "Installing documentation tools"

# Check if the target has markdown files
MARKDOWN_FILES=$(find "$TARGET_DIR" -name "*.md" | wc -l)
if [ "$MARKDOWN_FILES" -gt 0 ]; then
  if [ "$DRY_RUN" = false ] && [ "$CHECK_UPDATES_ONLY" = false ]; then
    # Check if markdown config needs updating
    MARKDOWN_CONFIG_FILE="$TARGET_DIR/.markdownlint.json"
    if [ ! -f "$MARKDOWN_CONFIG_FILE" ] || [ "$FORCE_OVERWRITE" = true ] || [ "$NEED_UPDATE" = true ]; then
      # Backup existing config if it exists
      if [ -f "$MARKDOWN_CONFIG_FILE" ]; then
        backup_file="${MARKDOWN_CONFIG_FILE}.backup.$(date +%Y%m%d%H%M%S)"
        cp "$MARKDOWN_CONFIG_FILE" "$backup_file"
        hooks_info "Backed up existing markdown config to: $backup_file"
      fi
      
      # Install markdownlint configuration
      cp "$SCRIPT_DIR/templates/markdownlint.json" "$MARKDOWN_CONFIG_FILE"
      hooks_success "Installed markdown linting configuration"
    else
      hooks_info "Markdown configuration is up to date"
    fi
  elif [ "$CHECK_UPDATES_ONLY" = true ]; then
    # Just check if markdown config needs updating
    MARKDOWN_CONFIG_FILE="$TARGET_DIR/.markdownlint.json"
    if [ ! -f "$MARKDOWN_CONFIG_FILE" ] || [ "$FORCE_OVERWRITE" = true ] || [ "$NEED_UPDATE" = true ]; then
      hooks_info "Update needed for markdown configuration"
    else
      hooks_info "Markdown configuration is up to date"
    fi
    
    # Copy markdown fixing scripts
    MARKDOWN_SCRIPTS_DIR="$HOOKS_DIR/scripts/markdown"
    mkdir -p "$MARKDOWN_SCRIPTS_DIR"
    
    if [ "$CHECK_UPDATES_ONLY" = false ]; then
      # Copy all markdown scripts with update checking
      for script_file in "$SCRIPT_DIR/scripts/markdown/"*.sh; do
        if [ -f "$script_file" ]; then
          script_name=$(basename "$script_file")
          target_script="$MARKDOWN_SCRIPTS_DIR/$script_name"
          
          # Check if script needs updating
          if [ ! -f "$target_script" ] || [ "$FORCE_OVERWRITE" = true ] || [ "$NEED_UPDATE" = true ] || ! cmp -s "$script_file" "$target_script"; then
            # Backup existing script if it exists
            if [ -f "$target_script" ]; then
              backup_file="${target_script}.backup.$(date +%Y%m%d%H%M%S)"
              cp "$target_script" "$backup_file"
              hooks_info "Backed up existing markdown script to: $backup_file"
            fi
            
            cp "$script_file" "$target_script"
            chmod +x "$target_script"
            hooks_info "Updated markdown script: $script_name"
          fi
        fi
      done
      
      hooks_success "Installed markdown fixing scripts"
    else
      # Just check if any scripts need updating
      SCRIPTS_NEED_UPDATE=false
      for script_file in "$SCRIPT_DIR/scripts/markdown/"*.sh; do
        if [ -f "$script_file" ]; then
          script_name=$(basename "$script_file")
          target_script="$MARKDOWN_SCRIPTS_DIR/$script_name"
          
          # Check if script needs updating
          if [ ! -f "$target_script" ] || [ "$FORCE_OVERWRITE" = true ] || [ "$NEED_UPDATE" = true ] || ! cmp -s "$script_file" "$target_script"; then
            hooks_info "Update needed for markdown script: $script_name"
            SCRIPTS_NEED_UPDATE=true
          fi
        fi
      done
      
      if [ "$SCRIPTS_NEED_UPDATE" = false ]; then
        hooks_info "All markdown scripts are up to date"
      fi
    fi
  else
    hooks_info "[DRY RUN] Would install markdown linting configuration and scripts"
  fi
fi

# Check if the target has YAML files
YAML_FILES=$(find "$TARGET_DIR" -name "*.yml" -o -name "*.yaml" | wc -l)
if [ "$YAML_FILES" -gt 0 ]; then
  if [ "$DRY_RUN" = false ]; then
    # Check if YAML config needs updating
    YAML_CONFIG_FILE="$TARGET_DIR/.yamllint.yml"
    if [ ! -f "$YAML_CONFIG_FILE" ] || [ "$FORCE_OVERWRITE" = true ] || [ "$NEED_UPDATE" = true ]; then
      # Backup existing config if it exists
      if [ -f "$YAML_CONFIG_FILE" ]; then
        backup_file="${YAML_CONFIG_FILE}.backup.$(date +%Y%m%d%H%M%S)"
        cp "$YAML_CONFIG_FILE" "$backup_file"
        hooks_info "Backed up existing YAML config to: $backup_file"
      fi
      
      # Install yamllint configuration
      cp "$SCRIPT_DIR/templates/yamllint.yml" "$YAML_CONFIG_FILE"
      hooks_success "Installed YAML linting configuration"
    else
      hooks_info "YAML configuration is up to date"
    fi
  else
    hooks_info "[DRY RUN] Would install YAML linting configuration"
  fi
fi

# Check if the target has JSON files
JSON_FILES=$(find "$TARGET_DIR" -name "*.json" | wc -l)
if [ "$JSON_FILES" -gt 0 ]; then
  if [ "$DRY_RUN" = false ]; then
    # Check if JSON config needs updating
    JSON_CONFIG_FILE="$TARGET_DIR/.jsonlintrc"
    if [ ! -f "$JSON_CONFIG_FILE" ] || [ "$FORCE_OVERWRITE" = true ] || [ "$NEED_UPDATE" = true ]; then
      # Backup existing config if it exists
      if [ -f "$JSON_CONFIG_FILE" ]; then
        backup_file="${JSON_CONFIG_FILE}.backup.$(date +%Y%m%d%H%M%S)"
        cp "$JSON_CONFIG_FILE" "$backup_file"
        hooks_info "Backed up existing JSON config to: $backup_file"
      fi
      
      # Install jsonlint configuration
      cp "$SCRIPT_DIR/templates/jsonlint.json" "$JSON_CONFIG_FILE"
      hooks_success "Installed JSON linting configuration"
    else
      hooks_info "JSON configuration is up to date"
    fi
  else
    hooks_info "[DRY RUN] Would install JSON linting configuration"
  fi
fi

# Check if the target has TOML files
TOML_FILES=$(find "$TARGET_DIR" -name "*.toml" | wc -l)
if [ "$TOML_FILES" -gt 0 ]; then
  if [ "$DRY_RUN" = false ]; then
    # Check if TOML config needs updating
    TOML_CONFIG_FILE="$TARGET_DIR/.tomllintrc"
    if [ ! -f "$TOML_CONFIG_FILE" ] || [ "$FORCE_OVERWRITE" = true ] || [ "$NEED_UPDATE" = true ]; then
      # Backup existing config if it exists
      if [ -f "$TOML_CONFIG_FILE" ]; then
        backup_file="${TOML_CONFIG_FILE}.backup.$(date +%Y%m%d%H%M%S)"
        cp "$TOML_CONFIG_FILE" "$backup_file"
        hooks_info "Backed up existing TOML config to: $backup_file"
      fi
      
      # Install TOML linting configuration
      cp "$SCRIPT_DIR/templates/tomllint.toml" "$TOML_CONFIG_FILE"
      hooks_success "Installed TOML linting configuration"
    else
      hooks_info "TOML configuration is up to date"
    fi
  else
    hooks_info "[DRY RUN] Would install TOML linting configuration"
  fi
fi

# Install GitHub workflow files if applicable
hooks_print_header "Setting up GitHub Workflows"
GITHUB_DIR="$TARGET_DIR/.github"
WORKFLOWS_DIR="$GITHUB_DIR/workflows"

# Check if this is a GitHub repository
if [ -d "$GITHUB_DIR" ] || [ -f "$TARGET_DIR/.gitlab-ci.yml" ]; then
  # Create workflows directory if it doesn't exist and not in check-only mode
  if [ "$DRY_RUN" = false ] && [ "$CHECK_UPDATES_ONLY" = false ]; then
    mkdir -p "$WORKFLOWS_DIR"
  fi
  
  # Detect project type and determine appropriate adapter
  PROJECT_TYPE="unknown"
  
  # Simple project type detection
  if [ -f "$TARGET_DIR/init.vim" ] || [ -f "$TARGET_DIR/init.lua" ]; then
    PROJECT_TYPE="nvim-config"
  elif [ -d "$TARGET_DIR/lua" ] && [ -d "$TARGET_DIR/plugin" ]; then
    PROJECT_TYPE="nvim-plugin"
  elif [ -f "$TARGET_DIR/rockspec" ] || [ -f "$TARGET_DIR/"*.rockspec ]; then
    PROJECT_TYPE="lua-lib"
  elif [ -f "$TARGET_DIR/mkdocs.yml" ] || [ -d "$TARGET_DIR/docs" ]; then
    PROJECT_TYPE="docs"
  fi
  
  hooks_info "Detected project type: $PROJECT_TYPE"
  
  # Process workflows based on mode
  if [ "$DRY_RUN" = false ] && [ "$CHECK_UPDATES_ONLY" = false ]; then
    # Full installation/update mode
    # Copy base workflow files
    for workflow in "$SCRIPT_DIR/ci/github/workflows/"*; do
      if [ -f "$workflow" ]; then
        workflow_name=$(basename "$workflow")
        target_workflow="$WORKFLOWS_DIR/$workflow_name"
        
        # Determine if there's an adapter-specific configuration
        adapter_config="$SCRIPT_DIR/ci/github/configs/$PROJECT_TYPE/${workflow_name%.*}.config.yml"
        
        # Check if workflow needs updating
        WORKFLOW_NEEDS_UPDATE=false
        
        if [ ! -f "$target_workflow" ] || [ "$FORCE_OVERWRITE" = true ] || [ "$NEED_UPDATE" = true ]; then
          WORKFLOW_NEEDS_UPDATE=true
        else
          # For workflows with adapter configurations, always update to ensure the merge is current
          if [ -f "$adapter_config" ]; then
            WORKFLOW_NEEDS_UPDATE=true
          # For base workflows, check if the source has changed
          elif ! cmp -s "$workflow" "$target_workflow"; then
            WORKFLOW_NEEDS_UPDATE=true
          fi
        fi
        
        if [ "$WORKFLOW_NEEDS_UPDATE" = true ]; then
          # Backup existing workflow if it exists
          if [ -f "$target_workflow" ]; then
            backup_file="${target_workflow}.backup.$(date +%Y%m%d%H%M%S)"
            cp "$target_workflow" "$backup_file"
            hooks_info "Backed up existing workflow to: $backup_file"
          fi
          
          # If adapter configuration exists, merge with base
          if [ -f "$adapter_config" ]; then
            hooks_info "Using adapter-specific configuration for $workflow_name"
            # Placeholder for actual YAML merging (simplified here)
            cat "$workflow" "$adapter_config" > "$target_workflow"
          else
            # Just copy the base workflow
            cp "$workflow" "$target_workflow"
          fi
          
          hooks_success "Installed workflow: $workflow_name"
        else
          hooks_info "Workflow $workflow_name is up to date"
        fi
      fi
    done
  elif [ "$CHECK_UPDATES_ONLY" = true ]; then
    # Check-only mode
    # Check base workflow files for updates
    for workflow in "$SCRIPT_DIR/ci/github/workflows/"*; do
      if [ -f "$workflow" ]; then
        workflow_name=$(basename "$workflow")
        target_workflow="$WORKFLOWS_DIR/$workflow_name"
        
        # Determine if there's an adapter-specific configuration
        adapter_config="$SCRIPT_DIR/ci/github/configs/$PROJECT_TYPE/${workflow_name%.*}.config.yml"
        
        # Check if workflow needs updating
        WORKFLOW_NEEDS_UPDATE=false
        
        if [ ! -f "$target_workflow" ] || [ "$FORCE_OVERWRITE" = true ] || [ "$NEED_UPDATE" = true ]; then
          WORKFLOW_NEEDS_UPDATE=true
        else
          # For workflows with adapter configurations, always update to ensure the merge is current
          if [ -f "$adapter_config" ]; then
            WORKFLOW_NEEDS_UPDATE=true
          # For base workflows, check if the source has changed
          elif ! cmp -s "$workflow" "$target_workflow"; then
            WORKFLOW_NEEDS_UPDATE=true
          fi
        fi
        
        if [ "$WORKFLOW_NEEDS_UPDATE" = true ]; then
          hooks_info "Update needed for workflow: $workflow_name"
        else
          hooks_info "Workflow $workflow_name is up to date"
        fi
      fi
    done
  else
    # Dry-run mode
    hooks_info "[DRY RUN] Would set up GitHub workflows for project type: $PROJECT_TYPE"
  fi
fi

# Install post-update hook
hooks_print_header "Setting up post-update hook"
if [ "$DRY_RUN" = false ] && [ "$CHECK_UPDATES_ONLY" = false ]; then
  # Copy the post-update hook script
  POST_UPDATE_SCRIPT="$HOOKS_DIR/scripts/update_hook.sh"
  POST_UPDATE_SCRIPT_DIR="$(dirname "$POST_UPDATE_SCRIPT")"
  mkdir -p "$POST_UPDATE_SCRIPT_DIR"
  
  # Check if update script needs updating
  SCRIPT_NEEDS_UPDATE=false
  
  if [ ! -f "$POST_UPDATE_SCRIPT" ] || [ "$FORCE_OVERWRITE" = true ] || [ "$NEED_UPDATE" = true ]; then
    SCRIPT_NEEDS_UPDATE=true
  elif ! cmp -s "$SCRIPT_DIR/scripts/update_hook.sh" "$POST_UPDATE_SCRIPT"; then
    SCRIPT_NEEDS_UPDATE=true
  fi
  
  if [ "$SCRIPT_NEEDS_UPDATE" = true ]; then
    # Backup existing script if it exists
    if [ -f "$POST_UPDATE_SCRIPT" ]; then
      backup_file="${POST_UPDATE_SCRIPT}.backup.$(date +%Y%m%d%H%M%S)"
      cp "$POST_UPDATE_SCRIPT" "$backup_file"
      hooks_info "Backed up existing update script to: $backup_file"
    fi
    
    cp "$SCRIPT_DIR/scripts/update_hook.sh" "$POST_UPDATE_SCRIPT"
    chmod +x "$POST_UPDATE_SCRIPT"
    hooks_info "Updated post-update script"
  else
    hooks_info "Post-update script is up to date"
  fi
  
  # Check and update post-merge hook
  POST_MERGE_HOOK="$HOOKS_DIR/post-merge"
  POST_MERGE_CONTENT='#!/bin/bash
# Auto-generated by hooks-util installer
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"$SCRIPT_DIR/scripts/update_hook.sh"
'
  
  HOOK_NEEDS_UPDATE=false
  if [ ! -f "$POST_MERGE_HOOK" ] || [ "$FORCE_OVERWRITE" = true ] || [ "$NEED_UPDATE" = true ]; then
    HOOK_NEEDS_UPDATE=true
  elif [ "$(cat "$POST_MERGE_HOOK")" != "$POST_MERGE_CONTENT" ]; then
    HOOK_NEEDS_UPDATE=true
  fi
  
  if [ "$HOOK_NEEDS_UPDATE" = true ]; then
    # Backup existing hook if it exists
    if [ -f "$POST_MERGE_HOOK" ]; then
      backup_file="${POST_MERGE_HOOK}.backup.$(date +%Y%m%d%H%M%S)"
      cp "$POST_MERGE_HOOK" "$backup_file"
      hooks_info "Backed up existing post-merge hook to: $backup_file"
    fi
    
    echo "$POST_MERGE_CONTENT" > "$POST_MERGE_HOOK"
    chmod +x "$POST_MERGE_HOOK"
    hooks_info "Updated post-merge hook"
  else
    hooks_info "Post-merge hook is up to date"
  fi
  
  # Check and update post-checkout hook
  POST_CHECKOUT_HOOK="$HOOKS_DIR/post-checkout"
  POST_CHECKOUT_CONTENT='#!/bin/bash
# Auto-generated by hooks-util installer
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"$SCRIPT_DIR/scripts/update_hook.sh" --quiet
'

  # Set up a post-update hook specifically for submodule updates
  POST_SUBMODULE_UPDATE_HOOK="$HOOKS_DIR/post-submodule-update"
  POST_SUBMODULE_UPDATE_CONTENT='#!/bin/bash
# Auto-generated by hooks-util installer
# This hook is called by the custom mechanism in .gitmodules to run after a submodule update
# It checks if the hooks-util submodule has been updated and runs the update if needed

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"$SCRIPT_DIR/scripts/update_hook.sh" --force
'
  
  HOOK_NEEDS_UPDATE=false
  if [ ! -f "$POST_CHECKOUT_HOOK" ] || [ "$FORCE_OVERWRITE" = true ] || [ "$NEED_UPDATE" = true ]; then
    HOOK_NEEDS_UPDATE=true
  elif [ "$(cat "$POST_CHECKOUT_HOOK")" != "$POST_CHECKOUT_CONTENT" ]; then
    HOOK_NEEDS_UPDATE=true
  fi
  
  if [ "$HOOK_NEEDS_UPDATE" = true ]; then
    # Backup existing hook if it exists
    if [ -f "$POST_CHECKOUT_HOOK" ]; then
      backup_file="${POST_CHECKOUT_HOOK}.backup.$(date +%Y%m%d%H%M%S)"
      cp "$POST_CHECKOUT_HOOK" "$backup_file"
      hooks_info "Backed up existing post-checkout hook to: $backup_file"
    fi
    
    echo "$POST_CHECKOUT_CONTENT" > "$POST_CHECKOUT_HOOK"
    chmod +x "$POST_CHECKOUT_HOOK"
    hooks_info "Updated post-checkout hook"
  else
    hooks_info "Post-checkout hook is up to date"
  fi
  
  # Check and update post-submodule-update hook
  HOOK_NEEDS_UPDATE=false
  if [ ! -f "$POST_SUBMODULE_UPDATE_HOOK" ] || [ "$FORCE_OVERWRITE" = true ] || [ "$NEED_UPDATE" = true ]; then
    HOOK_NEEDS_UPDATE=true
  elif [ "$(cat "$POST_SUBMODULE_UPDATE_HOOK")" != "$POST_SUBMODULE_UPDATE_CONTENT" ]; then
    HOOK_NEEDS_UPDATE=true
  fi
  
  if [ "$HOOK_NEEDS_UPDATE" = true ]; then
    # Backup existing hook if it exists
    if [ -f "$POST_SUBMODULE_UPDATE_HOOK" ]; then
      backup_file="${POST_SUBMODULE_UPDATE_HOOK}.backup.$(date +%Y%m%d%H%M%S)"
      cp "$POST_SUBMODULE_UPDATE_HOOK" "$backup_file"
      hooks_info "Backed up existing post-submodule-update hook to: $backup_file"
    fi
    
    echo "$POST_SUBMODULE_UPDATE_CONTENT" > "$POST_SUBMODULE_UPDATE_HOOK"
    chmod +x "$POST_SUBMODULE_UPDATE_HOOK"
    hooks_info "Updated post-submodule-update hook"
  else
    hooks_info "Post-submodule-update hook is up to date"
  fi
  
  # Provide instructions for using the gitmodules-hooks.sh script from hooks-util
  hooks_info ""
  hooks_info "IMPORTANT: To enable automatic submodule update hooks, add these lines to your shell config:"
  hooks_info "  source \"$SCRIPT_DIR/scripts/gitmodules-hooks.sh\""
  hooks_info "  alias git=git_with_hooks"
  
  hooks_success "Installed/updated post-update hooks"
elif [ "$CHECK_UPDATES_ONLY" = true ]; then
  # Just check if post-update hooks need updating
  
  # Check if update script needs updating
  POST_UPDATE_SCRIPT="$HOOKS_DIR/scripts/update_hook.sh"
  SCRIPT_NEEDS_UPDATE=false
  
  if [ ! -f "$POST_UPDATE_SCRIPT" ] || [ "$FORCE_OVERWRITE" = true ] || [ "$NEED_UPDATE" = true ]; then
    SCRIPT_NEEDS_UPDATE=true
    hooks_info "Update needed for post-update script"
  elif ! cmp -s "$SCRIPT_DIR/scripts/update_hook.sh" "$POST_UPDATE_SCRIPT"; then
    SCRIPT_NEEDS_UPDATE=true
    hooks_info "Update needed for post-update script"
  else
    hooks_info "Post-update script is up to date"
  fi
  
  # Check post-merge hook
  POST_MERGE_HOOK="$HOOKS_DIR/post-merge"
  POST_MERGE_CONTENT='#!/bin/bash
# Auto-generated by hooks-util installer
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"$SCRIPT_DIR/scripts/update_hook.sh"
'
  
  HOOK_NEEDS_UPDATE=false
  if [ ! -f "$POST_MERGE_HOOK" ] || [ "$FORCE_OVERWRITE" = true ] || [ "$NEED_UPDATE" = true ]; then
    HOOK_NEEDS_UPDATE=true
    hooks_info "Update needed for post-merge hook"
  elif [ "$(cat "$POST_MERGE_HOOK")" != "$POST_MERGE_CONTENT" ]; then
    HOOK_NEEDS_UPDATE=true
    hooks_info "Update needed for post-merge hook"
  else
    hooks_info "Post-merge hook is up to date"
  fi
  
  # Check post-checkout hook
  POST_CHECKOUT_HOOK="$HOOKS_DIR/post-checkout"
  POST_CHECKOUT_CONTENT='#!/bin/bash
# Auto-generated by hooks-util installer
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"$SCRIPT_DIR/scripts/update_hook.sh" --quiet
'
  
  HOOK_NEEDS_UPDATE=false
  if [ ! -f "$POST_CHECKOUT_HOOK" ] || [ "$FORCE_OVERWRITE" = true ] || [ "$NEED_UPDATE" = true ]; then
    HOOK_NEEDS_UPDATE=true
    hooks_info "Update needed for post-checkout hook"
  elif [ "$(cat "$POST_CHECKOUT_HOOK")" != "$POST_CHECKOUT_CONTENT" ]; then
    HOOK_NEEDS_UPDATE=true
    hooks_info "Update needed for post-checkout hook"
  else
    hooks_info "Post-checkout hook is up to date"
  fi
  
  # Check post-submodule-update hook
  POST_SUBMODULE_UPDATE_HOOK="$HOOKS_DIR/post-submodule-update"
  POST_SUBMODULE_UPDATE_CONTENT='#!/bin/bash
# Auto-generated by hooks-util installer
# This hook is called by the custom mechanism in .gitmodules to run after a submodule update
# It checks if the hooks-util submodule has been updated and runs the update if needed

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"$SCRIPT_DIR/scripts/update_hook.sh" --force
'
  
  HOOK_NEEDS_UPDATE=false
  if [ ! -f "$POST_SUBMODULE_UPDATE_HOOK" ] || [ "$FORCE_OVERWRITE" = true ] || [ "$NEED_UPDATE" = true ]; then
    HOOK_NEEDS_UPDATE=true
    hooks_info "Update needed for post-submodule-update hook"
  elif [ "$(cat "$POST_SUBMODULE_UPDATE_HOOK")" != "$POST_SUBMODULE_UPDATE_CONTENT" ]; then
    HOOK_NEEDS_UPDATE=true
    hooks_info "Update needed for post-submodule-update hook"
  else
    hooks_info "Post-submodule-update hook is up to date"
  fi
  
  # No need to check for .gitmodules-hooks anymore as we're using the one from hooks-util
else
  hooks_info "[DRY RUN] Would install/update:"
  hooks_info "- post-merge hook"
  hooks_info "- post-checkout hook"
  hooks_info "- post-submodule-update hook"
fi

# Run ensure_submodules.sh to ensure all required submodules are initialized
# This is especially important for lust-next which is needed for test quality validation
hooks_print_header "Ensuring submodules are properly initialized"
if [ "$DRY_RUN" = false ] && [ "$CHECK_UPDATES_ONLY" = false ]; then
  "${SCRIPT_DIR}/scripts/ensure_submodules.sh" -t "$TARGET_DIR"
else
  hooks_info "[DRY RUN/CHECK ONLY] Would ensure submodules are properly initialized"
fi

# Create a file to help track installed hook files
hooks_print_header "Creating hooks-util tracking file"
INSTALLED_FILES_LIST="$HOOKS_DIR/.hooks-util-files.txt"
if [ "$DRY_RUN" = false ] && [ "$CHECK_UPDATES_ONLY" = false ]; then
  {
    echo "# This file lists all files installed by hooks-util"
    echo "# Used for tracking what was added and needs to be committed"
    echo "# Last updated: $(date)"
    echo ""
    echo ".githooks/lib/"
    echo ".githooks/hooks/"
    echo ".githooks/scripts/"
    echo ".githooks/.hooks-util-files.txt"
    echo ".githooks/post-checkout"
    echo ".githooks/post-merge"
    echo ".githooks/post-submodule-update"
  } > "$INSTALLED_FILES_LIST"
  
  # Add the linting configuration files if they were installed
  if [ -f "$TARGET_DIR/.markdownlint.json" ]; then
    echo ".markdownlint.json" >> "$INSTALLED_FILES_LIST"
  fi
  if [ -f "$TARGET_DIR/.yamllint.yml" ]; then
    echo ".yamllint.yml" >> "$INSTALLED_FILES_LIST"
  fi
  if [ -f "$TARGET_DIR/.jsonlintrc" ]; then
    echo ".jsonlintrc" >> "$INSTALLED_FILES_LIST"
  fi
  if [ -f "$TARGET_DIR/.tomllintrc" ]; then
    echo ".tomllintrc" >> "$INSTALLED_FILES_LIST"
  fi
  if [ -d "$TARGET_DIR/.github/workflows" ]; then
    echo ".github/workflows/" >> "$INSTALLED_FILES_LIST"
  fi
  
  hooks_success "Created hooks-util tracking file: $INSTALLED_FILES_LIST"
  hooks_info "Review this file to see which files you should add to git"
else
  hooks_info "[DRY RUN/CHECK ONLY] Would create hooks-util tracking file at $INSTALLED_FILES_LIST"
fi

hooks_print_header "Installation complete"
hooks_success "Hooks are ready to use!"
hooks_info "Pre-commit hook will:"
hooks_info "- Format Lua files using StyLua"
hooks_info "- Run Luacheck for Lua code linting"
hooks_info "- Run ShellCheck for shell script validation"
hooks_info "- Validate Markdown files"
hooks_info "- Validate YAML, JSON, and TOML files"
hooks_info "- Fix common issues automatically:"
hooks_info "  - Trailing whitespace"
hooks_info "  - Line endings"
hooks_info "  - Prefix unused variables with _"
hooks_info "  - Add final newlines to files"
hooks_info "  - Fix markdown formatting issues"
hooks_info "- Run tests to ensure code quality"
hooks_info ""
hooks_info "IMPORTANT NEXT STEPS:"
hooks_info "1. Review the hooks-util tracking file at: $HOOKS_DIR/.hooks-util-files.txt"
hooks_info "2. Add the listed files to your git repository to track them:"
hooks_info "   git add \$(cat $HOOKS_DIR/.hooks-util-files.txt)"
hooks_info "3. Commit the changes to save your hooks configuration"
hooks_info ""
hooks_info "To customize, edit: $TARGET_DIR/.hooksrc"
hooks_info "Post-update hooks are installed to auto-update when the hooks-util submodule is updated"
hooks_info ""
hooks_info "NOTE: Installation creates backup files. To clean these up, run:"
hooks_info "  ${SCRIPT_DIR}/scripts/cleanup_backups.sh ${TARGET_DIR}"

exit 0