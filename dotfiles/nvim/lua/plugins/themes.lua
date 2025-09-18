local commands = require 'utils.commands'
local tables = require 'utils.tables'
local key = require('utils.misc').key
local uv = vim.uv

local current_theme_path = vim.fn.expand '$HOME/.config/omarchy/current/theme/neovim.lua'

local function read_theme()
    local ok, themes = pcall(dofile, current_theme_path)
    if ok and type(themes) == 'table' and themes[1] and themes[1].name then
        return themes[1].name
    end
    return nil
end

local function watch_theme_change()
    local handle = uv.new_fs_event()

    local dir_path = vim.fn.fnamemodify(current_theme_path, ':h')
    local theme_basename = vim.fn.fnamemodify(current_theme_path, ':t')

    local unwatch_cb = function()
        if handle then
            uv.fs_event_stop(handle)
        end
    end

    local event_cb = function(err, filename, events)
        if err then
            error 'Theme file watcher failed'
            unwatch_cb()
        elseif filename == theme_basename then
            local theme = read_theme(current_theme_path)
            if theme == 'snow' then
                set_light_mode()
            else
                set_dark_mode()
            end
        end
    end

    uv.fs_event_start(handle, dir_path, {
        watch_entry = false,
        stat = false,
        recursive = false,
    }, vim.schedule_wrap(event_cb))

    return handle
end

local function highlights(groups)
    for name, opts in pairs(groups) do
        local prev = vim.api.nvim_get_hl(0, { name = name })
        vim.api.nvim_set_hl(0, name, vim.tbl_extend('force', prev, opts))
    end
end

local function update(arg)
    local theme = arg and #arg > 0 and arg or vim.env.NVIM_THEME or 'default'
    local themes = vim.fn.getcompletion('*', 'color')
    local adjustments = {
        default = {
            Title = { fg = '#8cf8f7' },
        },

        poimandres = {
            Comment = { bg = 'none' },
            Title = { fg = '#5de4c7' },
            LspReferenceWrite = { bg = 'none' },
            LspReferenceText = { bg = 'none' },
            LspReferenceRead = { bg = 'none' },
            TelescopeResultsBorder = { fg = '#303340' },
            TelescopePreviewBorder = { fg = '#303340' },
        },

        blue = {
            Comment = { bg = 'none' },
        },
    }

    local cb = function(theme_name)
        vim.cmd.colorscheme(theme_name)

        vim.cmd [[
		hi clear MsgArea
		hi BiscuitColorlua guifg=#423F3D
		hi WinSeparator guifg=#222222
		hi FloatTitle guibg=none
		hi FloatBorder guibg=none guifg=#222222
		hi SignColumn guibg=none
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

        if adjustments[theme_name] then
            highlights(adjustments[theme_name])
        end
    end

    if tables.contains(themes, theme) then
        return cb(theme)
    end

    cb 'default'
end

local function setup(path, opts)
    opts = opts or {}
    local enabled = opts.enabled or false
    local setup_opts = opts.setup_opts or {}
    local theme_name = opts.theme_name
    local mod_name = opts.mod_name
    local call_setup = opts.call_setup ~= false

    local mod = path:sub(path:find '/' + 1)
    if mod:sub(-5) == '.nvim' then
        mod = mod:sub(1, -6)
    end

    mod = mod_name or mod
    local theme = theme_name or mod

    return {
        [1] = path,
        enabled = enabled,
        config = function()
            if call_setup then
                require(mod).setup(setup_opts)
            end

            if enabled then
                update(theme)
            end
        end,
        priority = 1000,
    }
end

function set_light_mode()
    update 'github_light_high_contrast'
    vim.api.nvim_set_option_value('background', 'light', {})
end

function set_dark_mode()
    update 'github_dark_high_contrast'
    vim.api.nvim_set_option_value('background', 'dark', {})
end

key('n', '<leader>tt', function()
    if vim.g.colors_name == 'github_light_high_contrast' then
        update 'github_dark_high_contrast'
    else
        update 'github_light_high_contrast'
    end
end)

key('n', '<leader>tT', function()
    if vim.env.NVIM_THEME ~= nil or vim.env.NVIM_THEME ~= '' then
        update(vim.env.NVIM_THEME)
    else
        update 'default'
    end
end)

commands.auto({ 'ColorScheme', 'UIEnter' }, {
    group = commands.augroup 'ColorSchemeUpdate',
    callback = update,
})

function set_theme()
    local theme = read_theme()

    if theme == nil then
        if vim.env.NVIM_THEME ~= nil or vim.env.NVIM_THEME ~= '' then
            update(vim.env.NVIM_THEME)
            return
        end

        update 'default'
        vim.api.nvim_set_option_value('background', 'dark', {})
        return
    end

    if theme == 'snow' then
        set_light_mode()
    else
        set_dark_mode()
    end

    watch_theme_change()
end

set_theme()

return {
    setup('ellisonleao/gruvbox.nvim', { enabled = false }),

    setup('projekt0n/github-nvim-theme', { enabled = true, theme_name = 'github_light_high_contrast', mod_name = 'github-theme' }),

    setup('olivercederborg/poimandres.nvim', {
        enabled = false,
        setup_opts = {
            dim_nc_background = true,
            disable_background = true,
            disable_float_background = true,
        },
    }),

    setup('sho-87/kanagawa-paper.nvim', {
        enabled = true,
        setup_opts = {
            transparent = true,
            dimInactive = true,
        },
    }),
}
