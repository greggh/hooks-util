#!/bin/bash
# Project template setup script
# Customizes the template files for a new project

set -e

echo "Project Setup Script"
echo "===================="
echo

# Get project information
read -p "Project name: " PROJECT_NAME
read -p "Project description: " PROJECT_DESCRIPTION
read -p "GitHub username: " GITHUB_USERNAME
read -p "Full name for license: " FULL_NAME
read -p "Email for security contacts: " EMAIL
YEAR=$(date +%Y)

echo
echo "Customizing project files..."

# Update README.md
sed -i "s/Project Template Repository/$PROJECT_NAME/g" README.md
sed -i "s/A comprehensive template repository with best practices for modern GitHub projects\./$PROJECT_DESCRIPTION/g" README.md

# Update CHANGELOG.md
sed -i "s/username\/project/$GITHUB_USERNAME\/$PROJECT_NAME/g" CHANGELOG.md

# Update LICENSE
sed -i "s/\[year\]/$YEAR/g" LICENSE
sed -i "s/\[fullname\]/$FULL_NAME/g" LICENSE

# Update CONTRIBUTING.md
sed -i "s/\[maintainer-email\]/$EMAIL/g" CONTRIBUTING.md
sed -i "s/username\/project-name/$GITHUB_USERNAME\/$PROJECT_NAME/g" CONTRIBUTING.md

# Update GitHub templates
sed -i "s/username\/project-name/$GITHUB_USERNAME\/$PROJECT_NAME/g" .github/ISSUE_TEMPLATE/config.yml
sed -i "s/security@example\.com/$EMAIL/g" SECURITY.md

# Update SUPPORT.md
sed -i "s/username\/project-name/$GITHUB_USERNAME\/$PROJECT_NAME/g" SUPPORT.md

echo
echo "Setup complete! Your project is ready to use."
echo
echo "Next steps:"
echo "1. Review and customize the documentation files"
echo "2. Set up your development environment"
echo "3. Start building your project"
echo
echo "Happy coding!"