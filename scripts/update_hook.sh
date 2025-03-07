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

# Find the root of the project (assumed to be parent directory of hooks-util)
cd "$(dirname "$(dirname "${BASH_SOURCE[0]}")")"
HOOKS_UTIL_DIR=$(pwd)
cd ..
PROJECT_ROOT=$(pwd)

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
    
    # Run the installer script with the collected arguments
    "$HOOKS_UTIL_DIR/install.sh" $INSTALL_ARGS --target "$PROJECT_ROOT"
    INSTALL_RESULT=$?
    
    if [ $INSTALL_RESULT -eq 0 ]; then
        log "Successfully updated hooks-util"
        
        # Update the version file with the current commit hash
        echo "$CURRENT_VERSION" > "$VERSION_FILE"
    else
        log "Error updating hooks-util"
        exit $INSTALL_RESULT
    fi
fi

exit 0