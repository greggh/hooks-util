#!/bin/bash

# Post-update hook script for hooks-util
# This script is designed to be invoked automatically after a git submodule update
# It detects if hooks-util has been updated and re-installs hooks if needed

# Function to display usage
display_usage() {
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  --force      Force reinstallation of hooks"
    echo "  --quiet      Quiet mode, less output"
    echo "  --help       Display this help message"
}

# Default options
FORCE_REINSTALL=false
QUIET=false
INSTALL_ARGS=""

# Parse command line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --force) FORCE_REINSTALL=true; INSTALL_ARGS="$INSTALL_ARGS --force" ;;
        --quiet) QUIET=true; INSTALL_ARGS="$INSTALL_ARGS --quiet" ;;
        --help) display_usage; exit 0 ;;
        *) echo "Unknown parameter: $1"; display_usage; exit 1 ;;
    esac
    shift
done

# Get current working directory
CURRENT_DIR=$(pwd)

# Find the root of the project and the hooks-util directory
SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_DIR_NAME="$(basename "$(dirname "$SCRIPT_PATH")")"

# Properly determine locations based on script location
if [[ "$SCRIPT_DIR_NAME" == "hooks-util" ]]; then
    # Script is in hooks-util/scripts (main repo case)
    HOOKS_UTIL_DIR="$(dirname "$SCRIPT_PATH")"
    PROJECT_ROOT="$(dirname "$HOOKS_UTIL_DIR")"
    HOOKS_DIR="${PROJECT_ROOT}/.githooks"
elif [[ "$SCRIPT_DIR_NAME" == ".githooks" ]]; then
    # Script is in .githooks/scripts (installed case)
    HOOKS_DIR="$(dirname "$SCRIPT_PATH")"
    PROJECT_ROOT="$(dirname "$HOOKS_DIR")"
    HOOKS_UTIL_DIR="${HOOKS_DIR}/hooks-util"
else
    # Fallback case
    echo -e "\033[0;31m\033[1mError:\033[0m \033[0;31mUnable to determine script location: ${SCRIPT_PATH}\033[0m"
    exit 1
fi

# Debug output for troubleshooting
if [ "${DEBUG:-0}" = "1" ]; then
    echo "SCRIPT_PATH: $SCRIPT_PATH"
    echo "HOOKS_UTIL_DIR: $HOOKS_UTIL_DIR"
    echo "HOOKS_DIR: $HOOKS_DIR"
    echo "PROJECT_ROOT: $PROJECT_ROOT"
fi

# Verify that PROJECT_ROOT is a git repository
if [ ! -d "${PROJECT_ROOT}/.git" ]; then
    echo -e "\033[0;31m\033[1mError:\033[0m \033[0;31mTarget directory is not a git repository: ${PROJECT_ROOT}\033[0m"
    exit 1
fi

# Go back to original directory
cd "$CURRENT_DIR"

# Function to log messages
log() {
    if [ "$QUIET" = false ]; then
        echo "[hooks-util post-update] $1"
    fi
}

# Check if we need to reinstall
if [ "$FORCE_REINSTALL" = true ]; then
    log "Forcing reinstallation of hooks-util"
    SHOULD_REINSTALL=true
else
    # Create or read the version file to detect changes
    VERSION_FILE="${PROJECT_ROOT}/.hooks-util-version"
    
    # Get current version from hooks-util
    CURRENT_VERSION=$(cd "$HOOKS_UTIL_DIR" && git rev-parse HEAD)
    
    # Always ensure VERSION_FILE is defined
    if [ -z "$VERSION_FILE" ]; then
        VERSION_FILE="${PROJECT_ROOT}/.hooks-util-version"
        log "Setting version file to default location: $VERSION_FILE"
    fi
    
    if [ -f "$VERSION_FILE" ]; then
        PREVIOUS_VERSION=$(cat "$VERSION_FILE")
        
        if [ "$CURRENT_VERSION" != "$PREVIOUS_VERSION" ]; then
            log "hooks-util has been updated from $PREVIOUS_VERSION to $CURRENT_VERSION"
            SHOULD_REINSTALL=true
        else
            log "hooks-util is already up to date"
            
            # Even when the commit hasn't changed, we'll do a version check
            # to ensure that non-git changes are also picked up
            INSTALL_ARGS="$INSTALL_ARGS --check-updates-only"
            SHOULD_REINSTALL=true
        fi
    else
        log "No previous version found, installing hooks-util"
        SHOULD_REINSTALL=true
    fi
fi

# Reinstall hooks if needed
if [ "$SHOULD_REINSTALL" = true ]; then
    log "Running hooks-util installer in $PROJECT_ROOT"
    
    # Check if template files exist in hooks-util and create if missing
    TEMPLATES_DIR="$HOOKS_UTIL_DIR/templates"
    mkdir -p "$TEMPLATES_DIR"
    
    # Create strict template files for testbed projects but standard templates for regular projects
    if [[ "$PROJECT_ROOT" == *"testbed"* ]] || [[ "$PROJECT_ROOT" == *"test-projects"* ]]; then
        log "Creating strict linting templates for testbed project"
        
        # For testbeds, create strict JSON template
        if [ ! -f "$TEMPLATES_DIR/jsonlint.json" ]; then
            echo '{
  "validateComments": true,
  "validateTrailingCommas": true,
  "allowDuplicateKeys": false,
  "allowEmptyStrings": false
}' > "$TEMPLATES_DIR/jsonlint.json"
            log "Created strict jsonlint.json template for testbed"
        fi

        # For testbeds, create strict markdown template
        if [ ! -f "$TEMPLATES_DIR/markdownlint.json" ]; then
            echo '{
  "default": true,
  "MD013": true,
  "MD024": true,
  "MD033": true
}' > "$TEMPLATES_DIR/markdownlint.json"
            log "Created strict markdownlint.json template for testbed"
        fi

        # For testbeds, create strict TOML template
        if [ ! -f "$TEMPLATES_DIR/tomllint.toml" ]; then
            echo '# TOML linting configuration
title = "TOML Lint Configuration for Testbed"

[lint]
missing_endline = "error"
incorrect_type = "error"
integer_bad_format = "error"
duplicate_key = "error"' > "$TEMPLATES_DIR/tomllint.toml"
            log "Created strict tomllint.toml template for testbed"
        fi

        # For testbeds, create strict YAML template
        if [ ! -f "$TEMPLATES_DIR/yamllint.yml" ]; then
            echo '---
extends: default

rules:
  line-length: enable
  truthy: enable
  document-start: enable
  indentation:
    spaces: 2
    indent-sequences: true' > "$TEMPLATES_DIR/yamllint.yml"
            log "Created strict yamllint.yml template for testbed"
        fi
    else
        # For regular projects, create standard templates
        if [ ! -f "$TEMPLATES_DIR/jsonlint.json" ]; then
            echo '{
  "validateComments": false,
  "validateTrailingCommas": false,
  "allowDuplicateKeys": false,
  "allowEmptyStrings": true
}' > "$TEMPLATES_DIR/jsonlint.json"
            log "Created standard jsonlint.json template"
        fi

        if [ ! -f "$TEMPLATES_DIR/markdownlint.json" ]; then
            echo '{
  "default": true,
  "MD013": false,
  "MD024": false,
  "MD033": false
}' > "$TEMPLATES_DIR/markdownlint.json"
            log "Created standard markdownlint.json template"
        fi

        if [ ! -f "$TEMPLATES_DIR/tomllint.toml" ]; then
            echo '# TOML linting configuration
title = "TOML Lint Configuration"

[lint]
missing_endline = "error"
incorrect_type = "error"
integer_bad_format = "error"' > "$TEMPLATES_DIR/tomllint.toml"
            log "Created standard tomllint.toml template"
        fi

        if [ ! -f "$TEMPLATES_DIR/yamllint.yml" ]; then
            echo '---
extends: default

rules:
  line-length: disable
  truthy: disable' > "$TEMPLATES_DIR/yamllint.yml"
            log "Created standard yamllint.yml template"
        fi
    fi
    
    # Run the installer script with the collected arguments
    # Check if install.sh exists in both potential locations
    if [ -f "$HOOKS_UTIL_DIR/install.sh" ]; then
        # Main repo case or submodule case
        "$HOOKS_UTIL_DIR/install.sh" $INSTALL_ARGS --target "$PROJECT_ROOT"
        INSTALL_RESULT=$?
    elif [ -f "$HOOKS_DIR/install.sh" ]; then
        # Installed case where install.sh is in .githooks directory
        "$HOOKS_DIR/install.sh" $INSTALL_ARGS --target "$PROJECT_ROOT"
        INSTALL_RESULT=$?
    else
        log "Error: install.sh not found in either $HOOKS_UTIL_DIR or $HOOKS_DIR"
        INSTALL_RESULT=1
    fi
    
    if [ $INSTALL_RESULT -eq 0 ]; then
        log "Successfully updated hooks-util"
        
        # Update the version file with the current commit hash
        if [ -n "$VERSION_FILE" ]; then
            echo "$CURRENT_VERSION" > "$VERSION_FILE"
        else
            log "Warning: VERSION_FILE is not defined. Cannot update version tracking file."
            # Create a default version file in the project root
            echo "$CURRENT_VERSION" > "${PROJECT_ROOT}/.hooks-util-version"
        fi
    else
        log "Error updating hooks-util"
        exit $INSTALL_RESULT
    fi
fi

exit 0