#!/bin/bash

# Script to fix common code block issues

# Function to display usage
display_usage() {
    echo "Usage: $0 [file-pattern]"
    echo ""
    echo "If no file pattern is provided, all *.md files in the current directory will be processed."
    echo "Examples:"
    echo "  $0                         # Process all *.md files in current directory"
    echo "  $0 docs/*.md               # Process only markdown files in docs directory"
    echo "  $0 README.md CHANGELOG.md  # Process specific files"
}

# Display usage if help requested
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    display_usage
    exit 0
fi

# Determine files to process
if [ $# -eq 0 ]; then
    # No arguments, use default pattern
    mapfile -t files < <(find . -name "*.md" -type f)
else
    # Use provided arguments
    files=("$@")
fi

# Process each file
for mdfile in "${files[@]}"; do
    echo "Checking file: $mdfile"

    # Use perl for better regex handling
    perl -i -pe 's/^```$/```text/' "$mdfile"
done

echo "Code block fixing complete"
