
# Project: hooks-util

## Overview

Hooks-Util is a comprehensive Git hooks framework for pre-commit validation across Neovim ecosystem projects. It features an adapter-based architecture to support different project types with specialized configurations, intelligent project type detection, and integration with lust-next for test quality validation. The framework now includes comprehensive documentation linting tools and a workflow management system with a base+adapter architecture.

## Essential Commands

- Install Hooks: `env -C /path/to/project /home/gregg/Projects/lua-library/hooks-util/install.sh`
- Run Tests: `env -C /home/gregg/Projects/lua-library/hooks-util ./spec/runner.lua`
- Run Core Tests: `env -C /home/gregg/Projects/lua-library/hooks-util ./spec/runner.lua "core"`
- Run Adapter Tests: `env -C /home/gregg/Projects/lua-library/hooks-util ./spec/runner.lua "adapters"`
- Run Tests With Tag: `env -C /home/gregg/Projects/lua-library/hooks-util ./spec/runner.lua "" "unit"`
- Check Formatting: `env -C /home/gregg/Projects/lua-library/hooks-util stylua lua/ -c`
- Run Linter: `env -C /home/gregg/Projects/lua-library/hooks-util luacheck lua/`

## Project Structure

- `/core`: Core functionality (adapter.lua, config.lua, registry.lua, markdown.lua, yaml.lua, json.lua, toml.lua, workflows.lua)
- `/adapters`: Project type adapters (nvim-plugin, nvim-config, lua-lib, docs)
- `/ci`: CI platform implementations including base workflow templates and adapter configurations
- `/templates`: Configuration templates for linting tools
- `/scripts`: Utility scripts including markdown fixing tools
- `/spec`: Test files using lust-next integration
- `/deps`: Dependencies (lust-next as submodule)
- `/lib`: Shared utilities including yaml_util.lua for workflow merging
- `install.sh`: Enhanced installation script with documentation tool and workflow support

## Current Focus

- Fix critical submodule and path issues:
  - [ ] Fix pre-commit hook's handling of submodule references
  - [ ] Fix update_hook.sh to properly handle both normal and submodule installations
  - [ ] Implement reliable template file distribution mechanism
  - [ ] Create proper file tracking system for git
  - [ ] Enhance error logging to better diagnose issues
- Fix pre-commit hook integration:
  - ✅ Created shell script wrappers (markdown.sh, yaml.sh, json.sh, toml.sh) for linting modules
  - ✅ Updated pre-commit hook to call these new functions
  - [ ] Fix remaining pre-commit hook execution issues
  - ✅ Created comprehensive testing scripts for each linting feature
  - [ ] Fix error handling for various edge cases
  - [ ] Test with various file types and edge cases
- Testing across all adapter types (after fixing critical issues):
  - [ ] Testing with lua-lib adapter (hooks-util-testbed-lua-lib)
  - [ ] Testing with nvim-plugin adapter (hooks-util-testbed-nvim-plugin)
  - [ ] Testing with nvim-config adapter (hooks-util-testbed-nvim-config)
  - [ ] Testing with docs adapter (hooks-util-testbed-docs)
- Deployment steps after testing:
  - Update base-project-repo with fully tested hooks-util v0.6.0
  - Propagate changes to template repositories
  - Deploy to end-product repositories

## Documentation Links

- Tasks: `/home/gregg/Projects/docs-projects/neovim-ecosystem-docs/tasks/hooks-util-tasks.md`
- Architecture: `/home/gregg/Projects/docs-projects/neovim-ecosystem-docs/plans/hooks-util-architecture.md`
- Adapter Specification: `/home/gregg/Projects/docs-projects/neovim-ecosystem-docs/specs/adapter-architecture.md`
- Test Quality Levels: `/home/gregg/Projects/docs-projects/neovim-ecosystem-docs/specs/test-quality-levels.md`
