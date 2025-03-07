#!/bin/bash
# Script to clean up backup files created during hooks-util installation

set -eo pipefail

# Get the target directory (default to current directory)
TARGET_DIR="${1:-$(pwd)}"

echo "Cleaning up backup files in: ${TARGET_DIR}"
echo "--------------------------------------------"

# Find and count all backup files
echo "Finding backup files..."
BACKUP_FILES=$(find "${TARGET_DIR}" -type f -name "*.backup*" 2>/dev/null || true)
BACKUP_DIRS=$(find "${TARGET_DIR}" -type d -name "lib.backup*" 2>/dev/null || true)

# Count files
BACKUP_FILE_COUNT=$(echo "${BACKUP_FILES}" | grep -v "^$" | wc -l || echo "0")
BACKUP_DIR_COUNT=$(echo "${BACKUP_DIRS}" | grep -v "^$" | wc -l || echo "0")

echo "Found ${BACKUP_FILE_COUNT} backup files and ${BACKUP_DIR_COUNT} backup directories"

# Ask for confirmation
if [ $((BACKUP_FILE_COUNT + BACKUP_DIR_COUNT)) -gt 0 ]; then
  echo ""
  echo "This will delete ALL backup files. Are you sure? (y/N)"
  read -r CONFIRM
  
  if [[ "${CONFIRM}" =~ ^[Yy]$ ]]; then
    # Delete backup files
    if [ "${BACKUP_FILE_COUNT}" -gt 0 ]; then
      echo "Deleting backup files..."
      for file in ${BACKUP_FILES}; do
        echo "  Removing: ${file}"
        rm -f "${file}"
      done
    fi
    
    # Delete backup directories
    if [ "${BACKUP_DIR_COUNT}" -gt 0 ]; then
      echo "Deleting backup directories..."
      for dir in ${BACKUP_DIRS}; do
        echo "  Removing: ${dir}"
        rm -rf "${dir}"
      done
    fi
    
    echo "Cleanup complete!"
  else
    echo "Operation cancelled by user"
    exit 0
  fi
else
  echo "No backup files found. Nothing to clean up."
fi