local commands = require 'utils.commands'
local tables = require 'utils.tables'

local function highlights(groups)
    for name, opts in pairs(groups) do
        local prev = vim.api.nvim_get_hl(0, { name = name })
        vim.api.nvim_set_hl(0, name, vim.tbl_extend('force', prev, opts))
    end
end

local function setup(path, opts)
    local module = path:sub(path:find '/' + 1)
    if module:sub(-5) == '.nvim' then
        module = module:sub(1, -6)
    end

    return {
        path,
        config = function()
            require(module).setup(opts or {})
        end,
        priority = 1000,
    }
end

commands.auto({ 'ColorScheme', 'UIEnter' }, {
    group = commands.augroup 'ColorSchemeUpdate',
    callback = function(arg)
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

        local cb = function(t)
            vim.opt.background = 'dark'
            vim.cmd.colorscheme(t)
            vim.cmd 'hi clear MsgArea'

            highlights {
                SignColumn = { bg = 'none' },
                StatusLine = { bg = 'none', fg = 'none' },
                StatusLineNC = { bg = 'none', fg = 'none' },
                Normal = { bg = 'none', ctermbg = 'none' },
                MsgSeparator = { bg = 'none', ctermbg = 'none' },
                TelescopePreviewNormal = { bg = 'none' },
                TelescopePreviewBorder = { bg = 'none' },
                TelescopeResultsNormal = { bg = 'none' },
                TelescopeResultsBorder = { bg = 'none' },
                TelescopePromptNormal = { bg = 'none' },
                TelescopePromptBorder = { bg = 'none' },
                LazyReasonSource = { bg = 'none', fg = '#5de4c7' },
                LazyReasonFt = { bg = 'none', fg = '#5de4c7' },
                NormalFloat = { bg = 'none' },
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
    end,
})

return {
    setup 'ellisonleao/gruvbox.nvim',

    setup 'wurli/cobalt.nvim',

    setup('olivercederborg/poimandres.nvim', {
        dim_nc_background = true,
        disable_background = true,
        disable_float_background = true,
    }),

    setup('sho-87/kanagawa-paper.nvim', {
        transparent = true,
        dimInactive = true,
    }),
}
