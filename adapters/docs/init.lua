-- adapters/docs/init.lua
-- Documentation project adapter for hooks-util

local M = {}

-- Detect if this is a documentation project
function M.detect(project_root)
  -- Check for common indicators of a documentation project
  local is_docs_project = false
  
  -- Check for MkDocs configuration
  local mkdocs_yml = io.open(project_root .. "/mkdocs.yml", "r")
  if mkdocs_yml then
    mkdocs_yml:close()
    is_docs_project = true
  end
  
  -- Check for docs directory with markdown files
  local has_docs_dir = false
  local lfs = require("lfs")
  local docs_dir = project_root .. "/docs"
  
  local docs_attr = lfs.attributes(docs_dir)
  if docs_attr and docs_attr.mode == "directory" then
    -- Check if there are markdown files in the docs directory
    for file in lfs.dir(docs_dir) do
      if file:match("%.md$") then
        has_docs_dir = true
        break
      end
    end
  end
  
  -- Additional indicators: significant number of markdown files
  local md_count = 0
  for file in lfs.dir(project_root) do
    if file:match("%.md$") then
      md_count = md_count + 1
      if md_count >= 5 then  -- Arbitrary threshold
        is_docs_project = true
        break
      end
    end
  end
  
  return is_docs_project or has_docs_dir
end

-- Get adapter name
function M.name()
  return "docs"
end

-- Get adapter description
function M.description()
  return "Documentation project adapter"
end

-- Setup adapter-specific configuration
function M.setup_config(config)
  -- Set documentation project defaults
  config = config or {}
  
  -- Enable markdown linting by default
  if config.markdown == nil then
    config.markdown = {}
  end
  config.markdown.enabled = true
  
  -- Enable YAML linting for MkDocs configuration
  if config.yaml == nil then
    config.yaml = {}
  end
  config.yaml.enabled = true
  
  -- Enable Lua linting and formatting if there are Lua files
  -- (some documentation projects may have Lua scripts)
  if config.stylua == nil then
    config.stylua = {
      enabled = true,
      config_file = ".stylua.toml",
      default_config = [[
# StyLua configuration for documentation projects
column_width = 100
line_endings = "Unix"
indent_type = "Spaces"
indent_width = 2
quote_style = "AutoPreferDouble"
call_parentheses = "Always"
]]
    }
  end
  
  if config.luacheck == nil then
    config.luacheck = {
      enabled = true,
      config_file = ".luacheckrc",
      default_config = [[
-- Luacheck configuration for documentation projects
std = {
  "lua51",
  "busted",
}

-- Global objects defined by the project
globals = {
  "vim",
  "describe",
  "it",
  "before_each",
  "after_each",
  "setup",
  "teardown",
  "pending",
  "assert"
}

-- Allow unused self argument (common in Lua methods)
self = false

-- Don't report unused arguments
unused_args = false

-- Maximum line length
max_line_length = 120
]]
    }
  end
  
  -- Set up workflows for documentation
  if config.workflows == nil then
    config.workflows = {}
  end
  config.workflows.docs = true
  config.workflows.markdown_lint = true
  config.workflows.yaml_lint = true
  config.workflows.scripts_lint = true  -- Enable script linting for Lua files
  
  return config
end

-- Validate documentation structure
function M.validate_docs_structure(project_root)
  local errors = {}
  local lfs = require("lfs")
  
  -- Check for docs directory
  local docs_dir = project_root .. "/docs"
  local docs_attr = lfs.attributes(docs_dir)
  if not docs_attr or docs_attr.mode ~= "directory" then
    table.insert(errors, "Missing docs directory")
  end
  
  -- Check for index.md or README.md
  local has_index = false
  local index_files = {
    project_root .. "/docs/index.md",
    project_root .. "/README.md"
  }
  
  for _, file_path in ipairs(index_files) do
    local file = io.open(file_path, "r")
    if file then
      file:close()
      has_index = true
      break
    end
  end
  
  if not has_index then
    table.insert(errors, "Missing index.md or README.md")
  end
  
  return #errors == 0, errors
end

-- Validate cross-references
function M.validate_cross_references(project_root)
  -- This would be a more complex implementation to check link validity
  -- For now, we'll just return success
  return true, {}
end

-- Get base workflows that apply to this adapter
function M.get_applicable_workflows()
  return {
    "ci.yml",
    "markdown-lint.yml",
    "yaml-lint.yml",
    "scripts-lint.yml",
    "docs.yml",
    "release.yml"
  }
end

-- Get workflow configurations for this adapter
function M.get_workflow_configs()
  return {
    "ci.config.yml",
    "docs.config.yml",
    "release.config.yml"
  }
end

-- Get linter configuration for documentation projects
function M.get_linter_config(project_root)
  -- Default linter configuration
  return {
    stylua = {
      enabled = true,
      config_file = ".stylua.toml",
      default_config = [[
# StyLua configuration for documentation projects
column_width = 100
line_endings = "Unix"
indent_type = "Spaces"
indent_width = 2
quote_style = "AutoPreferDouble"
call_parentheses = "Always"
]]
    },
    luacheck = {
      enabled = true,
      config_file = ".luacheckrc",
      default_config = [[
-- Luacheck configuration for documentation projects
std = {
  "lua51",
  "busted",
}

-- Global objects defined by the project
globals = {
  "vim",
  "describe",
  "it",
  "before_each",
  "after_each",
  "setup",
  "teardown",
  "pending",
  "assert"
}

-- Allow unused self argument (common in Lua methods)
self = false

-- Don't report unused arguments
unused_args = false

-- Maximum line length
max_line_length = 120
]]
    }
  }
end

-- Generate config files for the project if they don't exist
function M.generate_config(project_root)
  local success = true
  local messages = {}
  
  -- Generate stylua.toml if it doesn't exist (for Lua files in the project)
  local stylua_path = project_root .. "/.stylua.toml"
  local stylua_file = io.open(stylua_path, "r")
  if not stylua_file then
    local stylua_config = M.get_linter_config(project_root).stylua.default_config
    stylua_file = io.open(stylua_path, "w")
    if stylua_file then
      stylua_file:write(stylua_config)
      stylua_file:close()
      table.insert(messages, "Created StyLua configuration file")
    else
      success = false
      table.insert(messages, "Failed to create StyLua configuration file")
    end
  else
    stylua_file:close()
  end
  
  -- Generate luacheckrc if it doesn't exist (for Lua files in the project)
  local luacheckrc_path = project_root .. "/.luacheckrc"
  local luacheckrc_file = io.open(luacheckrc_path, "r")
  if not luacheckrc_file then
    local luacheckrc_config = M.get_linter_config(project_root).luacheck.default_config
    luacheckrc_file = io.open(luacheckrc_path, "w")
    if luacheckrc_file then
      luacheckrc_file:write(luacheckrc_config)
      luacheckrc_file:close()
      table.insert(messages, "Created Luacheck configuration file")
    else
      success = false
      table.insert(messages, "Failed to create Luacheck configuration file")
    end
  else
    luacheckrc_file:close()
  end
  
  -- Generate markdownlint configuration if it doesn't exist
  local markdownlint_path = project_root .. "/.markdownlint.json"
  local markdownlint_file = io.open(markdownlint_path, "r")
  if not markdownlint_file then
    local markdownlint_config = [[
{
  "default": true,
  "line-length": false,
  "no-duplicate-heading": false,
  "no-inline-html": false
}
]]
    markdownlint_file = io.open(markdownlint_path, "w")
    if markdownlint_file then
      markdownlint_file:write(markdownlint_config)
      markdownlint_file:close()
      table.insert(messages, "Created markdownlint configuration file")
    else
      success = false
      table.insert(messages, "Failed to create markdownlint configuration file")
    end
  else
    markdownlint_file:close()
  end
  
  -- Generate yamllint configuration if it doesn't exist
  local yamllint_path = project_root .. "/.yamllint.yml"
  local yamllint_file = io.open(yamllint_path, "r")
  if not yamllint_file then
    local yamllint_config = [[
extends: default

rules:
  line-length: disable
  document-start: disable
  truthy:
    allowed-values: ["true", "false", "yes", "no", "on", "off"]
  brackets:
    min-spaces-inside: 0
    max-spaces-inside: 1
  indentation:
    spaces: 2
    indent-sequences: consistent
]]
    yamllint_file = io.open(yamllint_path, "w")
    if yamllint_file then
      yamllint_file:write(yamllint_config)
      yamllint_file:close()
      table.insert(messages, "Created yamllint configuration file")
    else
      success = false
      table.insert(messages, "Failed to create yamllint configuration file")
    end
  else
    yamllint_file:close()
  end
  
  return success, messages
end

return M