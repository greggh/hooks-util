#!/bin/bash

# Script to fix common Markdown linting issues

# Function to add newlines to files
add_newlines() {
    local file="$1"
    if [ -f "$file" ]; then
        # Check if file ends with a newline
        if [ "$(tail -c 1 "$file" | wc -l)" -eq 0 ]; then
            echo "Adding newline to $file"
            echo "" >> "$file"
        fi
    fi
}

# Find all Markdown files
find /home/gregg/Projects/docs-projects/neovim-ecosystem-docs -name "*.md" -type f | while read -r file; do
    echo "Processing $file"

    # Add newline at the end of file
    add_newlines "$file"
done

echo "Markdown fixing complete"
