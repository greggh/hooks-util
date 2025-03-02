#!/bin/bash
# Non-interactive project template setup script
# Customizes the template files for a new project

set -e

echo "Non-interactive Project Setup Script"
echo "==================================="
echo

# Set project information from parameters
PROJECT_NAME="Neovim Hooks Utilities"
PROJECT_DESCRIPTION="A shared library of utilities for Git hooks across Lua-based Neovim projects"
GITHUB_USERNAME="greggh"
FULL_NAME="Gregg Housh"
EMAIL="g@0v.org"
YEAR=$(date +%Y)

echo
echo "Customizing project files..."

# Update README.md
sed -i "s/Project Template Repository/$PROJECT_NAME/g" README.md
sed -i "s/A comprehensive template repository with best practices for modern GitHub projects\./$PROJECT_DESCRIPTION/g" README.md

# Update CHANGELOG.md
sed -i "s/username\/project/$GITHUB_USERNAME\/hooks-util/g" CHANGELOG.md

# Update LICENSE
sed -i "s/\[year\]/$YEAR/g" LICENSE
sed -i "s/\[fullname\]/$FULL_NAME/g" LICENSE

# Update CONTRIBUTING.md
sed -i "s/\[maintainer-email\]/$EMAIL/g" CONTRIBUTING.md
sed -i "s/username\/project-name/$GITHUB_USERNAME\/hooks-util/g" CONTRIBUTING.md

# Update GitHub templates
sed -i "s/username\/project-name/$GITHUB_USERNAME\/hooks-util/g" .github/ISSUE_TEMPLATE/config.yml
sed -i "s/security@example\.com/$EMAIL/g" SECURITY.md

# Update SUPPORT.md
sed -i "s/username\/project-name/$GITHUB_USERNAME\/hooks-util/g" SUPPORT.md

echo
echo "Setup complete! Your project is ready to use."
echo
echo "Next steps:"
echo "1. Review and customize the documentation files"
echo "2. Set up your development environment"
echo "3. Start building your project"
echo
echo "Happy coding!"