#!/bin/bash
# test_github_workflows.sh - Script to validate GitHub Actions workflows locally
#
# This script helps test GitHub workflow files locally to identify issues
# before pushing to GitHub. It requires act (https://github.com/nektos/act)
# to be installed.

set -e

# Directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.." || exit 1

# Check if act is installed
if ! command -v act &> /dev/null; then
    echo "Error: act is not installed. Please install it to test GitHub workflows locally."
    echo "See https://github.com/nektos/act for installation instructions."
    exit 1
fi

# Directory for outputs
WORKFLOW_DIR=".github/workflows"
OUTPUT_DIR="./workflow-test-results"
mkdir -p "$OUTPUT_DIR"

# Print with color
print_header() {
  echo -e "\033[1;36m==== $1 ====\033[0m"
}

print_subheader() {
  echo -e "\033[1;34m--- $1 ---\033[0m"
}

print_success() {
  echo -e "\033[1;32m✓ $1\033[0m"
}

print_warning() {
  echo -e "\033[1;33m⚠ $1\033[0m"
}

print_error() {
  echo -e "\033[1;31m✗ $1\033[0m"
}

# Get all workflow files
mapfile -t workflow_files < <(find "$WORKFLOW_DIR" -name "*.yml" -type f)

if [ ${#workflow_files[@]} -eq 0 ]; then
    print_error "No workflow files found in $WORKFLOW_DIR"
    exit 1
fi

print_header "Found ${#workflow_files[@]} workflow files to test"

# Function to validate a single workflow file using act
validate_workflow() {
    local workflow_file="$1"
    local workflow_name
    workflow_name=$(basename "$workflow_file" .yml)
    
    print_subheader "Validating workflow: $workflow_name"
    
    # Run act with --dryrun to check for syntax errors
    act --dryrun -W "$workflow_file" > "$OUTPUT_DIR/$workflow_name-dryrun.log" 2>&1
    local act_exit_code=$?
    
    if [ $act_exit_code -eq 0 ]; then
        print_success "Workflow file $workflow_name passed basic validation"
        
        # Look for specific hooks-util related issues
        if grep -q "hooks-util" "$workflow_file"; then
            print_subheader "Checking hooks-util specific configuration..."
            
            # Check for skipped steps or disabled checks
            if grep -q "continue-on-error: true" "$workflow_file"; then
                print_warning "Workflow contains continue-on-error: true settings"
            fi
            
            if grep -q "if: false" "$workflow_file"; then
                print_error "Workflow contains disabled steps (if: false)"
            fi
            
            if grep -q "ignore_errors" "$workflow_file" || grep -q "ignore-errors" "$workflow_file"; then
                print_warning "Workflow may be ignoring errors"
            fi
        fi
    else
        print_error "Workflow file $workflow_name has validation errors"
    fi
    
    echo ""
}

# Validate each workflow file
for workflow in "${workflow_files[@]}"; do
    validate_workflow "$workflow"
done

# Generate a summary report
print_header "Generating summary report"

{
    echo "# GitHub Workflows Validation Summary"
    echo ""
    echo "## Test Environment"
    echo "- Date: $(date)"
    echo "- Hooks-Util Version: $(git rev-parse --short HEAD)"
    echo ""
    echo "## Workflow Files Tested"
    echo ""

    for workflow in "${workflow_files[@]}"; do
        workflow_name=$(basename "$workflow" .yml)
        if grep -q "error" "$OUTPUT_DIR/$workflow_name-dryrun.log"; then
            echo "- $workflow_name: ❌ Failed validation"
        else
            echo "- $workflow_name: ✅ Passed validation"
        fi
    done
    
    echo ""
    echo "## Issues Found"
    echo ""
    
    while IFS= read -r file; do
        if [ -n "$file" ]; then
            workflow_name=$(basename "$file" -dryrun.log)
            echo "### $workflow_name"
            grep -A 3 "error" "$file" | head -4 | sed 's/^/    /'
            echo ""
        fi
    done < <(grep -l "error" "$OUTPUT_DIR"/*.log 2>/dev/null || echo "")
    
    echo "## Recommendations"
    echo ""
    echo "1. Fix any syntax errors in workflow files"
    echo "2. Remove any disabled checks (if: false)"
    echo "3. Remove any continue-on-error settings unless absolutely necessary"
    echo "4. Test workflows on GitHub with a test branch after local validation passes"
} > "$OUTPUT_DIR/workflows-summary.md"

print_success "Summary report created at $OUTPUT_DIR/workflows-summary.md"
print_header "Workflow validation completed"