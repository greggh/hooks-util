#!/bin/bash
# Debugging script for hooks-util pre-commit hook

set -eo pipefail

# Determine script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOKS_UTIL_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Set verbose debugging
export HOOKS_VERBOSITY=2

echo "============ HOOKS DEBUGGING SCRIPT ============"
echo "Hooks-Util Root: ${HOOKS_UTIL_ROOT}"
echo "Current Directory: $(pwd)"

# Source the common library
source "${HOOKS_UTIL_ROOT}/lib/common.sh"
source "${HOOKS_UTIL_ROOT}/lib/error.sh"

# Display version information
echo "Hooks-Util Version: ${HOOKS_UTIL_VERSION}"

# Check for key tools
echo "Checking for required tools..."
tools=("markdownlint" "markdownlint-cli" "yamllint" "jsonlint" "tomlcheck")
for tool in "${tools[@]}"; do
  if hooks_command_exists "$tool"; then
    echo "✅ $tool is available"
  else
    echo "❌ $tool is not available"
  fi
done

# Check library paths
echo "Checking library paths..."
LIB_FILES=(
  "common.sh"
  "error.sh"
  "path.sh"
  "markdown.sh"
  "yaml.sh"
  "json.sh"
  "toml.sh"
)

for lib in "${LIB_FILES[@]}"; do
  if [ -f "${HOOKS_UTIL_ROOT}/lib/${lib}" ]; then
    echo "✅ ${lib} exists"
  else
    echo "❌ ${lib} does not exist"
  fi
done

# Check configuration loading
echo "Testing configuration loading..."
hooks_load_config "$@"
echo "HOOKS_STYLUA_ENABLED: ${HOOKS_STYLUA_ENABLED}"
echo "HOOKS_LUACHECK_ENABLED: ${HOOKS_LUACHECK_ENABLED}"
echo "HOOKS_TESTS_ENABLED: ${HOOKS_TESTS_ENABLED}"
echo "HOOKS_QUALITY_ENABLED: ${HOOKS_QUALITY_ENABLED}"

# Test TARGET_DIR initialization
echo "Testing TARGET_DIR initialization..."
TOP_LEVEL=$(hooks_git_root)
echo "Git Root: ${TOP_LEVEL}"
TARGET_DIR="${TOP_LEVEL}"
export TARGET_DIR
echo "TARGET_DIR: ${TARGET_DIR}"

# Test yaml.sh functions
echo "Testing yaml.sh functions..."
if [ -f "${HOOKS_UTIL_ROOT}/lib/yaml.sh" ]; then
  source "${HOOKS_UTIL_ROOT}/lib/yaml.sh"
  
  if [ -f "${TARGET_DIR}/.yamllint.yml" ]; then
    echo "✅ .yamllint.yml exists at ${TARGET_DIR}/.yamllint.yml"
  else
    echo "❌ .yamllint.yml does not exist at ${TARGET_DIR}/.yamllint.yml"
    
    # Check if it exists in the templates directory
    if [ -f "${HOOKS_UTIL_ROOT}/templates/.yamllint.yml" ]; then
      echo "✅ .yamllint.yml exists in templates directory"
    else
      echo "❌ .yamllint.yml does not exist in templates directory"
    fi
  fi
else
  echo "❌ yaml.sh not found"
fi

# Test markdown.sh functions
echo "Testing markdown.sh functions..."
if [ -f "${HOOKS_UTIL_ROOT}/lib/markdown.sh" ]; then
  source "${HOOKS_UTIL_ROOT}/lib/markdown.sh"
  
  MARKDOWN_SCRIPTS_DIR="${HOOKS_UTIL_ROOT}/scripts/markdown"
  if [ -d "${MARKDOWN_SCRIPTS_DIR}" ]; then
    echo "✅ Markdown scripts directory exists"
    ls -la "${MARKDOWN_SCRIPTS_DIR}"
  else
    echo "❌ Markdown scripts directory does not exist"
  fi
else
  echo "❌ markdown.sh not found"
fi

echo "============ DEBUGGING COMPLETE ============"