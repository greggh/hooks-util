#!/bin/bash

# Script to fix heading levels in markdown files
# Makes sure headings only increment by one level at a time

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
for file in "${files[@]}"; do
    echo "Processing $file for heading levels"

    # Create a temporary file
    temp_file=$(mktemp)

    # Process the file line by line
    last_level=0

    while IFS= read -r line; do
        # Check if line is a heading
        if [[ "$line" =~ ^(#+)[[:space:]] ]]; then
            # Get the heading level (number of # symbols)
            level=${#BASH_REMATCH[1]}

            # If this is the first heading, allow it to be any level
            if [[ $last_level -eq 0 ]]; then
                last_level=$level
                echo "$line" >> "$temp_file"
            else
                # Check if heading level increments by more than one
                if [[ $level -gt $((last_level + 1)) ]]; then
                    # Adjust the heading level
                    new_level=$((last_level + 1))
                    new_heading=$(printf "%${new_level}s" | tr ' ' '#')
                    new_line="${line#"${line%%[^#]*}"}"
                    echo "$new_heading$new_line" >> "$temp_file"
                    last_level=$new_level
                else
                    echo "$line" >> "$temp_file"
                    last_level=$level
                fi
            fi
        else
            # Not a heading
            echo "$line" >> "$temp_file"
        fi
    done < "$file"

    # Replace the original file with the fixed one
    mv "$temp_file" "$file"
done

echo "Heading levels fix complete"
