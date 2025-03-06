# Project: hooks-util

## Overview
Hooks-Util is a comprehensive Git hooks framework for pre-commit validation across Neovim ecosystem projects. It features an adapter-based architecture to support different project types with specialized configurations, intelligent project type detection, and integration with lust-next for test quality validation.

## Essential Commands
- Install Hooks: `cd /path/to/project && .githooks/hooks-util/install.sh`
- Run Tests: `env -C /home/gregg/Projects/hooks-util ./spec/runner.lua`
- Run Core Tests: `env -C /home/gregg/Projects/hooks-util ./spec/runner.lua "core"`
- Run Tests With Tag: `env -C /home/gregg/Projects/hooks-util ./spec/runner.lua "" "unit"`
- Check Formatting: `env -C /home/gregg/Projects/hooks-util stylua lua/ -c`
- Run Linter: `env -C /home/gregg/Projects/hooks-util luacheck lua/`

## Project Structure
- `/core`: Core functionality (adapter.lua, config.lua, registry.lua)
- `/adapters`: Project type adapters (neovim-plugin, neovim-config, lua-lib)
- `/ci`: CI platform implementations (GitHub Actions, GitLab CI)
- `/spec`: Test files using lust-next integration
- `/deps`: Dependencies (lust-next as submodule)
- `install.sh`: Main installation script

## Current Focus
- Completing comprehensive testing across all adapter types
- Finalizing documentation for the adapter system
- Preparing for integration as a git submodule in all projects
- Enhancing project type detection for edge cases
- Improving the test quality validation system

## Documentation Links
- Tasks: `/home/gregg/Projects/docs-projects/neovim-ecosystem-docs/tasks/hooks-util-tasks.md`
- Architecture: `/home/gregg/Projects/docs-projects/neovim-ecosystem-docs/plans/hooks-util-architecture.md`
- Adapter Specification: `/home/gregg/Projects/docs-projects/neovim-ecosystem-docs/specs/adapter-architecture.md`
- Test Quality Levels: `/home/gregg/Projects/docs-projects/neovim-ecosystem-docs/specs/test-quality-levels.md`