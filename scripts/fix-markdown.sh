#!/bin/bash
# Script to fix common Markdown linting issues

set -e

# Determine script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo "Fixing Markdown files in ${PROJECT_DIR}"

# Function to normalize a markdown file
fix_markdown_file() {
  local file="$1"
  echo "Processing $file"
  
  # Create a temp file
  local tempfile=$(mktemp)
  
  # Add trailing newline if missing
  if [ -f "$file" ] && [ "$(tail -c 1 "$file" | wc -l)" -eq 0 ]; then
    echo "Adding trailing newline to $file"
    cat "$file" > "$tempfile"
    echo >> "$tempfile"
    mv "$tempfile" "$file"
  fi
  
  # Fix headings not surrounded by blank lines
  sed -i -e 's/\([^\n]\)\n\(#\{1,6\}[ ]\)/\1\n\n\2/g' \
         -e 's/\(#\{1,6\}[ ].*\)\n\([^\n]\)/\1\n\n\2/g' "$file"
  
  # Fix lists not surrounded by blank lines
  sed -i -e 's/\([^\n]\)\n\([ ]*[-*+][ ]\)/\1\n\n\2/g' \
         -e 's/\([ ]*[-*+][ ].*\)\n\([^\n#]\)/\1\n\n\2/g' "$file"
}

# Find all Markdown files and fix them
find "${PROJECT_DIR}" -name "*.md" | while read -r file; do
  fix_markdown_file "$file"
done

echo "Markdown files fixed successfully"