# AGENTS.md - Development Guidelines

This is a personal dotfiles repository containing configuration files for various tools (Neovim, Hyprland, Tmux, etc.).

## Build/Test Commands

This repository contains configuration files only, so there are no traditional build/test commands.

**For Bash scripts:**
```bash
# Run any script with bash -n for syntax checking
bash -n path/to/script.sh
```

**For Neovim Lua configs:**
```bash
# Lint and format Lua files
stylua --check dotfiles/nvim/
stylua dotfiles/nvim/
```

**For TypeScript/JavaScript (if any):**
```bash
# Check and format with Biome
biome check
biome check --write
biome format --write
```

**Setup:**
```bash
# Run the setup script to create symlinks
./setup
# Force delete existing configs
./setup --force
```

## Code Style Guidelines

### Lua (Neovim Configuration)

**Imports:**
- Use single quotes for simple module names: `require 'module'`
- Use parentheses for module with submodules: `require('module.submodule')`
- Import modules at the top of files
- Create local aliases for frequently used functions: `local key = require('utils.misc').key`

**Formatting (stylua):**
- 4-space indentation
- 160 character line width
- Prefer single quotes over double quotes
- No trailing commas in function calls
- Empty lines between top-level functions

**Naming Conventions:**
- Use module pattern: `local M = {}`
- Public functions: `M.function_name`
- Local functions: `local function_name`
- Variables: `snake_case`
- Constants: `UPPER_CASE`

**Types:**
- Add type annotations with EmmyLua: `---@param name string`
- Use `---@return type` for return values
- Use `---@type` for complex types

**Error Handling:**
- Use early returns for error conditions
- Display errors with `vim.notify(message, vim.log.levels.ERROR)`
- Use `error()` for critical failures
- Return `nil, err` pattern for recoverable errors

**Code Structure:**
- Each file should return `M` at the end
- Use `vim.api.nvim_*` for API calls
- Use `vim.opt.*` for options (aliased as `o`)
- Use `vim.g.*` for global variables (aliased as `g`)

### Bash Scripts

**Shebang:**
- Always use `#!/usr/bin/env bash`

**Safety:**
- Start scripts with `set -euo pipefail`
- Quote all variable expansions: `"$VAR"`
- Use `local` for function variables

**Naming:**
- Functions: `snake_case`
- Constants: `UPPER_CASE`
- Variables: `lower_case`

**Formatting:**
- 4-space indentation
- Use `[[` for tests instead of `[`
- Use `$()` instead of backticks
- Long commands: use backslash continuation

**Error Handling:**
- Check exit codes explicitly when needed
- Print errors to stderr: `echo 'error: message' >&2`
- Use `exit 1` for failures
- Return meaningful exit codes

**Functions:**
- Define functions before use
- Add comments for complex logic
- Use `return` instead of `exit` in functions

### Configuration Files (JSON, TOML, YAML)

**General:**
- 2-space indentation for most configs (JSONC, TOML)
- 4-space indentation for Lua configs
- Use trailing commas in JSON/YAML where allowed
- Add comments where supported

**Hyprland:**
- Use `source` to include other configs
- Override defaults in separate files
- Keep custom settings at the end

**Waybar:**
- Group related modules
- Use consistent icon themes
- Add descriptive tooltips

**Tmux/Zellij:**
- Keep keybindings organized by mode
- Use consistent prefixes
- Add comments for complex bindings

### General Guidelines

**File Organization:**
- Keep configs in `dotfiles/` subdirectories by tool
- Place scripts in `bin/` directory
- Use descriptive filenames

**Comments:**
- Keep comments concise and meaningful
- Prefer code that is self-documenting
- Document non-obvious behavior

**Version Control:**
- Commit logical changes together
- Write descriptive commit messages
- Test changes before committing

**Neovim Specific:**
- Use Lazy for plugin management
- Configure LSP servers in `lua/plugins/lsp.lua`
- Add keybindings in `lua/core/keymaps.lua`
- Define custom commands in `lua/core/commands.lua`

**Bash Specific:**
- Make scripts executable: `chmod +x bin/script.sh`
- Test scripts in a safe environment
- Use shellcheck for additional linting if available
