#!/bin/bash

# Script to fix common code block issues

# Define the directory to process
DOCS_DIR="/home/gregg/Projects/docs-projects/neovim-ecosystem-docs"

# Find all markdown files
find "$DOCS_DIR" -name "*.md" -type f | while read -r mdfile; do
    echo "Checking file: $mdfile"

    # Use perl for better regex handling
    perl -i -pe 's/^```$/```text/' "$mdfile"
done

echo "Code block fixing complete"
