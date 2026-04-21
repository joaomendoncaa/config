-- ============================================================================
-- THEME MANAGER: Pulls theme from Omarchy, detects light/dark,
-- applies highlight overrides, and watches for changes.
-- ============================================================================

local commands = require 'utils.commands'

-- ============================================================================
-- 1. HELPERS: Read Omarchy theme config (text-based, no dofile)
-- ============================================================================

---@return string|nil colorscheme_name
---@return string|nil plugin_repo
local function read_omarchy_theme()
    local path = vim.fn.expand '~/.config/omarchy/current/theme/neovim.lua'
    if vim.fn.filereadable(path) ~= 1 then
        return nil, nil
    end

    local lines = vim.fn.readfile(path)
    if not lines or #lines == 0 then
        return nil, nil
    end

    -- Join into a single string for easier pattern matching
    local content = table.concat(lines, '\n')

    -- Strategy 1: Extract colorscheme from LazyVim/LazyVim opts (most reliable)
    -- Pattern handles: colorscheme = "kanagawa", colorscheme="catppuccin", etc.
    local colorscheme = content:match 'colorscheme%s*=%s*"([^"]+)"'

    -- Strategy 2: Extract the first non-LazyVim plugin repo
    -- Pattern: "owner/repo" where repo is not "LazyVim"
    local plugin_repo = content:match '"([%w_.-]+/[^"]+)"'
    if plugin_repo and plugin_repo:match 'LazyVim/LazyVim' then
        -- If the first match is LazyVim, try the next one
        plugin_repo = content:match '"[^"]+"[^"]*"([%w_.-]+/[^"]+)"'
    end

    return colorscheme, plugin_repo
end

-- ============================================================================
-- 2. HELPERS: Detect light/dark from Omarchy colors
-- ============================================================================

local function detect_background()
    local ghostty_path = vim.fn.expand '~/.config/omarchy/current/theme/ghostty.conf'
    local colors_path = vim.fn.expand '~/.config/omarchy/current/theme/colors.toml'
    local bg_hex = nil

    -- Try ghostty.conf first
    if vim.fn.filereadable(ghostty_path) == 1 then
        for _, line in ipairs(vim.fn.readfile(ghostty_path)) do
            local hex = line:match '^background%s*=%s*(#[0-9a-fA-F]+)'
            if hex then
                bg_hex = hex:lower()
                break
            end
        end
    end

    -- Fallback to colors.toml
    if not bg_hex and vim.fn.filereadable(colors_path) == 1 then
        for _, line in ipairs(vim.fn.readfile(colors_path)) do
            local hex = line:match '^background%s*=%s*"(#[0-9a-fA-F]+)"'
            if hex then
                bg_hex = hex:lower()
                break
            end
        end
    end

    if not bg_hex then
        return 'dark'
    end

    -- Calculate relative luminance
    local r = tonumber(bg_hex:sub(2, 3), 16) / 255
    local g = tonumber(bg_hex:sub(4, 5), 16) / 255
    local b = tonumber(bg_hex:sub(6, 7), 16) / 255
    local lum = 0.2126 * r + 0.7152 * g + 0.0722 * b

    return lum > 0.5 and 'light' or 'dark'
end

-- ============================================================================
-- 3. HIGHLIGHT OVERRIDES
-- ============================================================================

local function apply_highlights()
    vim.cmd [[
        hi clear MsgArea
        hi BiscuitColorlua guifg=#423F3D
        hi WinSeparator guifg=#222222
        hi FloatTitle guibg=none
        hi FloatBorder guibg=none guifg=#222222
        hi SignColumn guibg=none
        hi NvimTreeNormal guibg=none
        hi NvimTreeVertSplit guibg=none
        hi NvimTreeEndOfBuffer guibg=none
        hi StatusLine guibg=none guifg=none
        hi StatusLineNC guibg=none guifg=none
        hi Normal guibg=none ctermbg=none
        hi NormalFloat guibg=none
        hi FloatBorder guibg=none
        hi Pmenu guibg=none
        hi Terminal guibg=none
        hi EndOfBuffer guibg=none
        hi FoldColumn guibg=none
        hi Folded guibg=none
        hi NormalNC guibg=none
        hi CursorLine guibg=none
        hi MsgSeparator guibg=none ctermbg=none
        hi LspReferenceText guibg=none
        hi LspReferenceRead guibg=none
        hi LspReferenceWrite guibg=none
        hi MiniCursorword guibg=none
        hi MiniCursorwordCurrent guibg=none
        hi TelescopePreviewNormal guibg=none
        hi TelescopePreviewBorder guibg=none
        hi TelescopeResultsNormal guibg=none
        hi TelescopeResultsBorder guibg=none
        hi TelescopePromptNormal guibg=none
        hi TelescopePromptBorder guibg=none
        hi LazyReasonSource guibg=none guifg=#5de4c7
        hi LazyReasonFt guibg=none guifg=#5de4c7
        hi DiagnosticSignOk guibg=none
        hi DiagnosticSignHint guibg=none
        hi DiagnosticSignInfo guibg=none
        hi DiagnosticSignWarn guibg=none
        hi DiagnosticSignError guibg=none
    ]]
end

-- ============================================================================
-- 4. THEME APPLICATION
-- ============================================================================

local last_colorscheme = nil
local is_exiting = false

local function apply_theme(colorscheme_name)
    if is_exiting then
        return
    end

    local target = colorscheme_name or 'default'

    -- Set background BEFORE colorscheme so the colorscheme can react to it
    local bg = detect_background()
    if vim.o.background ~= bg then
        vim.o.background = bg
    end

    local ok = pcall(vim.cmd.colorscheme, target)

    if not ok and target ~= 'default' then
        vim.notify('Theme "' .. target .. '" not available, falling back to default', vim.log.levels.WARN)
        pcall(vim.cmd.colorscheme, 'default')
    end

    -- Explicitly apply highlights right away (don't rely solely on ColorScheme autocmd)
    apply_highlights()
end

-- ============================================================================
-- 5. WATCH FOR OMARCHY THEME CHANGES
-- ============================================================================

local active_watcher = nil
local pending_timer = nil

local function check_and_apply_theme()
    if is_exiting then
        return
    end

    local colorscheme, _ = read_omarchy_theme()

    if colorscheme and colorscheme ~= last_colorscheme then
        last_colorscheme = colorscheme
        apply_theme(colorscheme)
    elseif not colorscheme then
        if last_colorscheme ~= 'default' then
            last_colorscheme = 'default'
            apply_theme 'default'
        end
    end
end

local function debounced_check()
    -- Cancel any pending delayed check
    if pending_timer then
        pending_timer:stop()
        pending_timer:close()
        pending_timer = nil
    end

    -- Immediate check
    check_and_apply_theme()

    -- Retry once after 500ms in case the file was mid-write
    local uv = vim.uv or vim.loop
    pending_timer = uv.new_timer()
    pending_timer:start(
        500,
        0,
        vim.schedule_wrap(function()
            pending_timer = nil
            check_and_apply_theme()
        end)
    )
end

local function start_watching()
    local uv = vim.uv or vim.loop
    local name_file = vim.fn.expand '~/.config/omarchy/current/theme.name'

    active_watcher = {}

    -- Try fs_event for near-instant updates
    local fs_event = uv.new_fs_event()
    if fs_event then
        local ok, err = fs_event:start(name_file, {}, function()
            vim.schedule(debounced_check)
        end)
        if ok then
            active_watcher.fs_event = fs_event
        else
            fs_event:close()
        end
    end

    -- Polling fallback every 3 seconds (reliable, lightweight)
    local timer = uv.new_timer()
    timer:start(3000, 3000, vim.schedule_wrap(debounced_check))
    active_watcher.timer = timer
end

local function stop_watching()
    if pending_timer then
        pending_timer:stop()
        pending_timer:close()
        pending_timer = nil
    end
    if not active_watcher then
        return
    end
    if active_watcher.fs_event then
        active_watcher.fs_event:stop()
        active_watcher.fs_event:close()
    end
    if active_watcher.timer then
        active_watcher.timer:stop()
        active_watcher.timer:close()
    end
    active_watcher = nil
end

-- ============================================================================
-- 6. SETUP AUTOCMDS
-- ============================================================================

local augroup = commands.augroup('UserThemeManager', { clear = true })

-- Reapply highlights after EVERY colorscheme change (safety net)
commands.auto('ColorScheme', {
    group = augroup,
    callback = apply_highlights,
})

-- Reapply highlights after everything is loaded (other plugins might override)
commands.auto('VimEnter', {
    group = augroup,
    once = true,
    callback = function()
        apply_highlights()
    end,
})

-- Stop watchers and mark as exiting to prevent last-minute color changes
commands.auto('VimLeavePre', {
    group = augroup,
    callback = function()
        is_exiting = true
        stop_watching()
    end,
})

-- Start watching after all plugins are loaded
commands.auto('VimEnter', {
    group = augroup,
    once = true,
    callback = function()
        check_and_apply_theme()
        start_watching()
    end,
})

-- ============================================================================
-- 7. RETURN LAZY PLUGIN SPEC
-- ============================================================================

local colorscheme, plugin_repo = read_omarchy_theme()

if plugin_repo then
    return {
        {
            plugin_repo,
            priority = 1000,
            lazy = false,
            config = function()
                apply_theme(colorscheme)
            end,
        },
    }
else
    -- No omarchy theme found: apply default on startup
    commands.auto('VimEnter', {
        group = augroup,
        once = true,
        callback = function()
            apply_theme 'default'
        end,
    })
    return {}
end
