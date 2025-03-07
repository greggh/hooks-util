
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

- Validate fixes and continue testing:
  - [x] Fix VERSION_FILE issue (properly handled empty version file and removed warning)
  - [x] Validate infinite recursion protection in quality.sh (confirmed it works correctly)
  - [ ] Test pre-commit hooks across all adapter types
  - [ ] Fix GitHub workflow failures in neovim-ecosystem-docs
  - [ ] Remove any disabling of linting checks in template files

- Fix critical submodule and CI issues:
  - [x] Fix project root detection in update_hook.sh
  - [x] Fix install.sh path finding and availability
  - [x] Enhanced version tracking with proper fallbacks
  - [x] Fix pre-commit hook's handling of submodule references
  - [x] Fix infinite recursion issue in hooks_fix_staged_quality
  - [x] Fix update_hook.sh to properly handle both normal and submodule installations
  - [ ] Create proper file tracking system for git
  - [ ] Enhance error logging to better diagnose issues

- Fix shellcheck and tool detection:
  - [ ] Fix shellcheck detection across all environments (attempted but needs validation)
  - [ ] Add comprehensive fallback mechanisms for all required tools
  - [ ] Implement better error reporting when tools are missing
  - [ ] Test tool detection with various installation methods

- Implement comprehensive testing strategy:
  - [ ] Create a standardized testing procedure for hooks-util
  - [ ] Implement automated test suite for all functionality
  - [ ] Document testing approach in TESTING.md
  - [ ] Test all fixes across all adapter types
  - [ ] Create test automation scripts for continuous validation

- Only after fixing critical issues:
  - [ ] Testing with lua-lib adapter (hooks-util-testbed-lua-lib)
  - [ ] Testing with nvim-plugin adapter (hooks-util-testbed-nvim-plugin)
  - [ ] Testing with nvim-config adapter (hooks-util-testbed-nvim-config)
  - [ ] Testing with docs adapter (hooks-util-testbed-docs)
  - [ ] Update base-project-repo with fully tested hooks-util
  - [ ] Propagate changes to template repositories
  - [ ] Deploy to end-product repositories

## Debugging and Testing Commands

- Debug Pre-commit: `env -C /home/gregg/Projects/lua-library/hooks-util DEBUG=1 ./scripts/debug_hooks.sh`
- Debug Tests: `env -C /home/gregg/Projects/lua-library/hooks-util DEBUG=1 ./scripts/debug_test.sh`
- Diagnose Installation: `env -C /home/gregg/Projects/lua-library/hooks-util DEBUG=1 ./scripts/diagnose.sh`
- Check Submodules: `env -C /home/gregg/Projects/lua-library/hooks-util ./scripts/ensure_submodules.sh`
- Test Hooks in Debug Mode: `env -C /path/to/project DEBUG=1 ./.githooks/pre-commit`
- Force Reinstall: `env -C /path/to/project ./.githooks/hooks-util/install.sh --force`
- Test All Formats: `env -C /home/gregg/Projects/lua-library/hooks-util ./scripts/test_all_formats.sh`
- Test Integration: `env -C /home/gregg/Projects/lua-library/hooks-util ./scripts/run_integration_tests.sh`
- Run Testbed Validation: `env -C /home/gregg/Projects/test-projects/hooks-util-testbed-nvim-plugin ./validate-hooks.sh`

## Known Issues

- **Workflow Failures**: CI pipelines failing in both primary repositories
- **Infinite Recursion**: Pre-commit hook can enter infinite loop with staged files
- **Shellcheck Detection**: Inconsistent shellcheck finding across environments
- **Template Distribution**: Issues with template files being created correctly
- **Check Suppression**: Problematic disabling of checks in template files
- **Incomplete Testing**: Validation gaps across adapter types

## Documentation Links

- Tasks: `/home/gregg/Projects/docs-projects/neovim-ecosystem-docs/tasks/hooks-util-tasks.md`
- Architecture: `/home/gregg/Projects/docs-projects/neovim-ecosystem-docs/plans/hooks-util-architecture.md`
- Adapter Specification: `/home/gregg/Projects/docs-projects/neovim-ecosystem-docs/specs/adapter-architecture.md`
- Test Quality Levels: `/home/gregg/Projects/docs-projects/neovim-ecosystem-docs/specs/test-quality-levels.md`
