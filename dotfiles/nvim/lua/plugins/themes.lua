local commands = require 'utils.commands'
local tables = require 'utils.tables'
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

    vim.notify('Updating colorscheme: ' .. vim.inspect(theme), vim.inspect(themes))

    local cb = function(t)
        vim.cmd.colorscheme(t)
        vim.cmd [[
		hi clear MsgArea
		hi BiscuitColorlua guifg=#423F3D
		hi WinSeparator guifg=#222222
		hi FloatTitle guibg=none
		hi FloatBorder guibg=none guifg=#222222
		hi SignColumn guibg=none
	]]

        highlights {
            SignColumn = { bg = 'none' },
            NvimTreeNormal = { bg = 'none' },
            NvimTreeVertSplit = { bg = 'none' },
            NvimTreeEndOfBuffer = { bg = 'none' },
            StatusLine = { bg = 'none', fg = 'none' },
            StatusLineNC = { bg = 'none', fg = 'none' },
            Normal = { bg = 'none', ctermbg = 'none' },
            NormalFloat = { bg = 'none' },
            FloatBorder = { bg = 'none' },
            Pmenu = { bg = 'none' },
            Terminal = { bg = 'none' },
            EndOfBuffer = { bg = 'none' },
            FoldColumn = { bg = 'none' },
            Folded = { bg = 'none' },
            NormalNC = { bg = 'none' },
            CursorLine = { bg = 'none' },
            MsgSeparator = { bg = 'none', ctermbg = 'none' },
            TelescopePreviewNormal = { bg = 'none' },
            TelescopePreviewBorder = { bg = 'none' },
            TelescopeResultsNormal = { bg = 'none' },
            TelescopeResultsBorder = { bg = 'none' },
            TelescopePromptNormal = { bg = 'none' },
            TelescopePromptBorder = { bg = 'none' },
            LazyReasonSource = { bg = 'none', fg = '#5de4c7' },
            LazyReasonFt = { bg = 'none', fg = '#5de4c7' },
            DiagnosticSignOk = { bg = 'none' },
            DiagnosticSignHint = { bg = 'none' },
            DiagnosticSignInfo = { bg = 'none' },
            DiagnosticSignWarn = { bg = 'none' },
            DiagnosticSignError = { bg = 'none' },
        }

        if adjustments[t] then
            highlights(adjustments[t])
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

commands.auto({ 'ColorScheme', 'UIEnter' }, {
    group = commands.augroup 'ColorSchemeUpdate',
    callback = update,
})

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
        enabled = false,
        setup_opts = {
            transparent = true,
            dimInactive = true,
        },
    }),
}
