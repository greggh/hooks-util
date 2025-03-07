#!/bin/bash

# Script to add newlines to the end of files that are missing them

# GitHub workflow YAML files
for file in /home/gregg/Projects/docs-projects/neovim-ecosystem-docs/.github/workflows/*.yml; do
    if [ -f "$file" ]; then
        # Check if file ends with a newline
        if [ "$(tail -c 1 "$file" | wc -l)" -eq 0 ]; then
            echo "Adding newline to $file"
            echo "" >> "$file"
        fi
    fi
done

# Check other YAML files
for file in /home/gregg/Projects/docs-projects/neovim-ecosystem-docs/templates/FUNDING.yml /home/gregg/Projects/docs-projects/neovim-ecosystem-docs/.yamllint.yml /home/gregg/Projects/docs-projects/neovim-ecosystem-docs/.pre-commit-config.yaml; do
    if [ -f "$file" ]; then
        # Check if file ends with a newline
        if [ "$(tail -c 1 "$file" | wc -l)" -eq 0 ]; then
            echo "Adding newline to $file"
            echo "" >> "$file"
        fi
    fi
done

echo "Newline fixing complete"
