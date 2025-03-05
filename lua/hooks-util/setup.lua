-- hooks-util/lua/hooks-util/setup.lua
-- Interactive setup wizard for hooks-util
local M = {}

-- Helper function to read user input
local function read_input(prompt, default)
  io.write(prompt .. (default and " [" .. default .. "]" or "") .. ": ")
  io.flush()
  local input = io.read()
  if input == "" and default then
    return default
  end
  return input
end

-- Helper function to read user choice from a list
local function read_choice(prompt, choices)
  io.write("\n" .. prompt .. ":\n")
  
  -- Display choices
  for i, choice in ipairs(choices) do
    io.write(string.format("  [%d] %s\n", i, choice.name))
  end
  
  io.write("\nEnter your choice [1-" .. #choices .. "]: ")
  io.flush()
  
  local input = io.read()
  local choice_num = tonumber(input)
  
  if choice_num and choice_num >= 1 and choice_num <= #choices then
    return choices[choice_num]
  else
    io.write("Invalid choice. Please try again.\n")
    return read_choice(prompt, choices)
  end
end

-- Helper function to read yes/no input
local function read_yes_no(prompt, default)
  local default_str
  if default == true then
    default_str = "Y/n"
  elseif default == false then
    default_str = "y/N"
  else
    default_str = "y/n"
  end
  
  io.write(prompt .. " [" .. default_str .. "]: ")
  io.flush()
  
  local input = io.read():lower()
  
  if input == "" and default ~= nil then
    return default
  elseif input == "y" or input == "yes" then
    return true
  elseif input == "n" or input == "no" then
    return false
  else
    io.write("Please answer 'y' or 'n'.\n")
    return read_yes_no(prompt, default)
  end
end

-- Run the interactive setup wizard
function M.run_wizard(project_root)
  local registry = require('hooks-util.core.registry')
  local config = require('hooks-util.core.config')
  
  -- Print welcome message
  io.write([[
=====================================================
        Hooks-Util Interactive Setup Wizard
=====================================================

This wizard will guide you through setting up hooks-util
for your project. It will:

1. Detect or select the appropriate project type
2. Generate configuration files for linting and testing
3. Set up git hooks for code quality and testing
4. Configure CI workflow templates

]])

  -- Step 1: Detect or select project type
  local available_adapters = registry.get_all_adapters()
  
  if #available_adapters == 0 then
    io.write("Error: No adapters found. Please check your installation.\n")
    return false, "No adapters found"
  end
  
  io.write("Step 1: Detecting project type...\n")
  
  -- Try to auto-detect the project type
  local detected_adapter, _ = registry.detect_adapter(project_root)
  local selected_adapter
  
  if detected_adapter then
    io.write(string.format("Detected project type: %s (%s)\n", 
      detected_adapter.name, detected_adapter.description))
    
    local use_detected = read_yes_no("Use detected project type?", true)
    if use_detected then
      selected_adapter = detected_adapter
    end
  else
    io.write("Could not auto-detect project type.\n")
  end
  
  -- If no adapter was selected yet, let the user choose
  if not selected_adapter then
    selected_adapter = read_choice("Select project type", available_adapters)
    io.write(string.format("Selected project type: %s (%s)\n", 
      selected_adapter.name, selected_adapter.description))
  end
  
  -- Step 2: Configure linting options
  io.write("\nStep 2: Configuring linting options...\n")
  
  local linter_config = selected_adapter:get_linter_config(project_root)
  
  -- StyLua
  local use_stylua = read_yes_no("Enable StyLua code formatting?", 
    linter_config.stylua and linter_config.stylua.enabled or true)
  
  -- Luacheck
  local use_luacheck = read_yes_no("Enable Luacheck code linting?",
    linter_config.luacheck and linter_config.luacheck.enabled or true)
  
  -- Step 3: Configure testing options
  io.write("\nStep 3: Configuring testing options...\n")
  
  local test_config = selected_adapter:get_test_config(project_root)
  
  -- Testing framework
  local use_tests = read_yes_no("Enable test running in pre-commit hooks?",
    test_config and test_config.enabled or true)
  
  local test_framework = nil
  if use_tests then
    local framework_choices = {
      { name = "lust-next (Recommended)", value = "lust-next" },
      { name = "Plenary.nvim (for Neovim plugins)", value = "plenary" },
      { name = "Busted", value = "busted" },
      { name = "Makefile test target", value = "make" },
    }
    
    local framework_choice = read_choice("Select testing framework", framework_choices)
    test_framework = framework_choice.value
    
    -- Ask about setting up test structure
    local setup_tests = read_yes_no("Generate basic test structure?", true)
    if setup_tests then
      if test_framework == "lust-next" then
        local lust_next = require('hooks-util.lust-next')
        local success, message = lust_next.setup_project(project_root)
        if success then
          io.write("Successfully set up lust-next test structure.\n")
        else
          io.write("Failed to set up lust-next: " .. message .. "\n")
        end
      else
        io.write("Test structure generation not yet implemented for " .. test_framework .. ".\n")
      end
    end
  end
  
  -- Step 4: Configure CI options
  io.write("\nStep 4: Configuring CI options...\n")
  
  local ci_platform_choices = {
    { name = "GitHub Actions", value = "github" },
    { name = "GitLab CI", value = "gitlab" },
    { name = "Azure DevOps", value = "azure" },
    { name = "None (Skip CI setup)", value = "none" },
  }
  
  local ci_platform_choice = read_choice("Select primary CI platform", ci_platform_choices)
  local primary_platform = ci_platform_choice.value
  
  if primary_platform ~= "none" then
    -- Generate CI workflow
    if test_framework == "lust-next" then
      local lust_next = require('hooks-util.lust-next')
      local success, message = lust_next.generate_workflow(project_root, primary_platform)
      if success then
        io.write("Successfully generated " .. primary_platform .. " workflow for lust-next.\n")
      else
        io.write("Failed to generate workflow: " .. message .. "\n")
      end
    else
      io.write("CI workflow generation not yet implemented for " .. test_framework .. ".\n")
    end
  end
  
  -- Step 5: Generate configuration file
  io.write("\nStep 5: Generating hooks-util configuration...\n")
  
  -- Create configuration structure
  local hooks_util_config = {
    project_type = selected_adapter.name,
    
    linting = {
      enabled = true,
      stylua = {
        enabled = use_stylua,
      },
      luacheck = {
        enabled = use_luacheck,
      },
    },
    
    testing = {
      enabled = use_tests,
      framework = test_framework,
    },
    
    ci = {
      primary_platform = primary_platform ~= "none" and primary_platform or nil,
    },
    
    hooks = {
      pre_commit = {
        enabled = true,
        run_linters = true,
        run_tests = use_tests,
      },
    },
  }
  
  -- Save configuration
  config.config = hooks_util_config
  local success, err = config.save_config(project_root .. "/hooks-util.config.lua")
  
  if success then
    io.write("Successfully generated hooks-util.config.lua\n")
  else
    io.write("Failed to save configuration: " .. (err or "unknown error") .. "\n")
  end
  
  -- Step 6: Install hooks
  io.write("\nStep 6: Installing git hooks...\n")
  
  local install_hooks = read_yes_no("Install pre-commit hooks now?", true)
  if install_hooks then
    local cmd = project_root .. "/.githooks/hooks-util/install.sh -c"
    local result = os.execute(cmd)
    if result == 0 then
      io.write("Successfully installed git hooks.\n")
    else
      io.write("Failed to install git hooks.\n")
    end
  end
  
  -- Completion message
  io.write([[

=====================================================
           Setup Completed Successfully
=====================================================

Your project has been configured with:
- Project type: ]] .. selected_adapter.name .. [[

- Linting: ]] .. (use_stylua and "StyLua (enabled), " or "StyLua (disabled), ") .. 
                 (use_luacheck and "Luacheck (enabled)" or "Luacheck (disabled)") .. [[

- Testing: ]] .. (use_tests and (test_framework or "enabled") or "disabled") .. [[

- CI Platform: ]] .. (primary_platform ~= "none" and primary_platform or "none") .. [[


Configuration has been saved to hooks-util.config.lua

Run 'hooks-util install' if you need to reinstall the hooks.
]])

  return true, "Setup completed successfully"
end

return M