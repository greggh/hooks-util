#!/bin/bash
# Script to clean up backup files created during hooks-util installation

# Turn off strict mode as we're handling errors ourselves
set +e

# Get the target directory (default to current directory)
TARGET_DIR="${1:-$(pwd)}"

echo "Cleaning up backup files in: ${TARGET_DIR}"
echo "--------------------------------------------"

# Find and count all backup files
echo "Finding backup files..."
BACKUP_FILES=$(find "${TARGET_DIR}" -type f -name "*.backup*" 2>/dev/null)
BACKUP_DIRS=$(find "${TARGET_DIR}" -type d -name "lib.backup*" 2>/dev/null)

# Count files
BACKUP_FILE_COUNT=0
if [ -n "${BACKUP_FILES}" ]; then
  BACKUP_FILE_COUNT=$(echo "${BACKUP_FILES}" | wc -l)
fi

BACKUP_DIR_COUNT=0
if [ -n "${BACKUP_DIRS}" ]; then
  BACKUP_DIR_COUNT=$(echo "${BACKUP_DIRS}" | wc -l)
fi

echo "Found ${BACKUP_FILE_COUNT} backup files and ${BACKUP_DIR_COUNT} backup directories"

# Ask for confirmation
if [ "${BACKUP_FILE_COUNT}" -gt 0 ] || [ "${BACKUP_DIR_COUNT}" -gt 0 ]; then
  echo ""
  echo "This will delete ALL backup files. Are you sure? (y/N)"
  read -r CONFIRM
  
  if [[ "${CONFIRM}" =~ ^[Yy]$ ]]; then
    # Delete backup files
    if [ "${BACKUP_FILE_COUNT}" -gt 0 ]; then
      echo "Deleting backup files..."
      echo "${BACKUP_FILES}" | while read -r file; do
        if [ -n "${file}" ] && [ -f "${file}" ]; then
          echo "  Removing: ${file}"
          rm -f "${file}"
        fi
      done
    fi
    
    # Delete backup directories
    if [ "${BACKUP_DIR_COUNT}" -gt 0 ]; then
      echo "Deleting backup directories..."
      echo "${BACKUP_DIRS}" | while read -r dir; do
        if [ -n "${dir}" ] && [ -d "${dir}" ]; then
          echo "  Removing: ${dir}"
          rm -rf "${dir}"
        fi
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