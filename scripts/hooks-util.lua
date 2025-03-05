#!/usr/bin/env lua
-- hooks-util CLI utility
-- Provides a command-line interface for hooks-util functionality

-- Add the project directory to package.path
local script_path = arg[0]
local project_root = script_path:match("(.+)/scripts/hooks%-util%.lua$")
if not project_root then
  project_root = ".."
end

package.path = project_root .. "/?.lua;" .. package.path
package.path = project_root .. "/?/init.lua;" .. package.path

-- Import the hooks-util library
local hooks_util = require("hooks-util")

-- Command-line argument parsing
local function parse_args()
  local cmd = arg[1]
  local options = {}
  
  for i = 2, #arg do
    local key, value = arg[i]:match("^%-%-([^=]+)=(.+)$")
    if key then
      options[key] = value
    else
      key = arg[i]:match("^%-%-(.+)$")
      if key then
        options[key] = true
      else
        options[i-1] = arg[i]
      end
    end
  end
  
  return cmd, options
end

-- Show help text
local function show_help()
  print("Hooks-Util CLI v" .. hooks_util.version)
  print("Usage: hooks-util COMMAND [OPTIONS]")
  print("")
  print("Commands:")
  print("  setup              Run the interactive setup wizard")
  print("  install            Install hooks for a project")
  print("  detect             Detect the appropriate adapter for a project")
  print("  generate-config    Generate configuration files")
  print("  install-ci         Install CI workflow templates")
  print("")
  print("Options:")
  print("  --project-root=PATH     Project root directory (default: current directory)")
  print("  --adapter=NAME          Use specific adapter (default: auto-detect)")
  print("  --platform=PLATFORM     CI platform for install-ci (github, gitlab, azure)")
  print("  --force                 Force overwrite of existing files")
  print("  --verbose               Show detailed output")
  print("  --help                  Show this help message")
  print("")
  print("Examples:")
  print("  hooks-util setup")
  print("  hooks-util install --project-root=/path/to/project")
  print("  hooks-util generate-config --adapter=nvim-plugin")
  print("  hooks-util install-ci --platform=github")
end

-- Main function
local function main()
  -- Parse command-line arguments
  local cmd, options = parse_args()
  
  -- Handle help command
  if not cmd or cmd == "help" or options["help"] then
    show_help()
    os.exit(0)
  end
  
  -- Project root directory
  local project_root = options["project-root"] or os.getenv("PWD")
  
  -- Execute command
  if cmd == "setup" then
    print("Running setup wizard...")
    local ok, err = hooks_util.setup_wizard(project_root)
    if not ok then
      print("Error: " .. (err or "Unknown error"))
      os.exit(1)
    end
  elseif cmd == "install" then
    print("Installing hooks...")
    local ok, err = hooks_util.install_hooks(project_root, options["force"])
    if not ok then
      print("Error: " .. (err or "Unknown error"))
      os.exit(1)
    end
  elseif cmd == "detect" then
    print("Detecting adapter...")
    local adapter, err = hooks_util.get_adapter(project_root)
    if not adapter then
      print("Error: " .. (err or "No adapter found"))
      os.exit(1)
    end
    print("Detected adapter: " .. adapter.name)
    print("Description: " .. adapter.description)
    print("Version: " .. adapter.version)
  elseif cmd == "generate-config" then
    print("Generating configuration...")
    local ok, err = hooks_util.generate_config(project_root, options["adapter"])
    if not ok then
      print("Error: " .. (err or "Unknown error"))
      os.exit(1)
    end
  elseif cmd == "install-ci" then
    if not options["platform"] then
      print("Error: Missing required option --platform")
      os.exit(1)
    end
    print("Installing CI workflow templates...")
    local ok, err = hooks_util.install_ci_templates(project_root, options["platform"])
    if not ok then
      print("Error: " .. (err or "Unknown error"))
      os.exit(1)
    end
  else
    print("Unknown command: " .. cmd)
    show_help()
    os.exit(1)
  end
  
  print("Operation completed successfully.")
end

-- Run the main function
main()