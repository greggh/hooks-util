#!/bin/bash

# Script to fix list numbering in markdown files
# Resets section numbering to start from 1 after each heading

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
    # Store find results in an array
    mapfile -t files < <(find . -name "*.md" -type f)
else
    # Use provided arguments
    files=("$@")
fi

# Process each file
if [ $# -eq 0 ]; then
    # Process files found by find command
    for file in "${files[@]}"; do
    # Check if file exists and is readable
    if [ ! -f "$file" ] || [ ! -r "$file" ]; then
        echo "Warning: Cannot read file $file, skipping."
        continue
    fi

    echo "Processing $file for list numbering"

    # Create a temporary file
    temp_file=$(mktemp)

    # Process the file line by line
    in_list=false
    list_counter=0
    previous_line=""

    while IFS= read -r line; do
        # Check if line is a heading
        if [[ "$line" =~ ^#+ ]]; then
            in_list=false
            list_counter=0
            echo "$line" >> "$temp_file"
            previous_line="$line"
            continue
        fi

        # Check if line is an ordered list item
        if [[ "$line" =~ ^[[:space:]]*[0-9]+\. ]]; then
            # If previous line was empty or a heading, start a new list
            if [[ "$previous_line" =~ ^[[:space:]]*$ || "$previous_line" =~ ^#+ ]]; then
                in_list=true
                list_counter=1
                # Replace the number with 1
                echo "${line/[0-9]\./$list_counter\.}" >> "$temp_file"
            else
                # Continue the list
                if [ "$in_list" = true ]; then
                    list_counter=$((list_counter + 1))
                    # Replace the number with the current counter
                    echo "${line/[0-9]\./$list_counter\.}" >> "$temp_file"
                else
                    echo "$line" >> "$temp_file"
                fi
            fi
        else
            # Not a list item
            echo "$line" >> "$temp_file"
            # Check if we're exiting a list
            if [[ "$line" =~ ^[[:space:]]*$ && "$in_list" = true ]]; then
                in_list=false
                list_counter=0
            fi
        fi

        previous_line="$line"
    done < "$file"

    # Replace the original file with the fixed one
    mv "$temp_file" "$file"
    done
else
    # Process files from arguments
    for file in "${files[@]}"; do
        # Check if file exists and is readable
        if [ ! -f "$file" ] || [ ! -r "$file" ]; then
            echo "Warning: Cannot read file $file, skipping."
            continue
        fi

        echo "Processing $file for list numbering"

        # Create a temporary file
        temp_file=$(mktemp)

        # Process the file line by line
        in_list=false
        list_counter=0
        previous_line=""

        while IFS= read -r line; do
            # Check if line is a heading
            if [[ "$line" =~ ^#+ ]]; then
                in_list=false
                list_counter=0
                echo "$line" >> "$temp_file"
                previous_line="$line"
                continue
            fi

            # Check if line is an ordered list item
            if [[ "$line" =~ ^[[:space:]]*[0-9]+\. ]]; then
                # If previous line was empty or a heading, start a new list
                if [[ "$previous_line" =~ ^[[:space:]]*$ || "$previous_line" =~ ^#+ ]]; then
                    in_list=true
                    list_counter=1
                    # Replace the number with 1
                    echo "${line/[0-9]\./$list_counter\.}" >> "$temp_file"
                else
                    # Continue the list
                    if [ "$in_list" = true ]; then
                        list_counter=$((list_counter + 1))
                        # Replace the number with the current counter
                        echo "${line/[0-9]\./$list_counter\.}" >> "$temp_file"
                    else
                        echo "$line" >> "$temp_file"
                    fi
                fi
            else
                # Not a list item
                echo "$line" >> "$temp_file"
                # Check if we're exiting a list
                if [[ "$line" =~ ^[[:space:]]*$ && "$in_list" = true ]]; then
                    in_list=false
                    list_counter=0
                fi
            fi

            previous_line="$line"
        done < "$file"

        # Replace the original file with the fixed one
        mv "$temp_file" "$file"
    done
fi

echo "List numbering fix complete"
