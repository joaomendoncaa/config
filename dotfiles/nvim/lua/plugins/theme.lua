return {
    -- Poimandres colorscheme for Neovim written in Lua.
    -- SEE: https://github.com/olivercederborg/poimandres.nvim
    'olivercederborg/poimandres.nvim',

    priority = 1000,

    config = function()
        local poimandres = require 'poimandres'
        local themes = require 'utils.themes'
        local cmd = vim.cmd
        local initial = vim.env.NVIM_THEME or 'default'

        poimandres.setup {
            dim_nc_background = true,
            disable_background = true,
            disable_float_background = true,
        }

        cmd.colorscheme(initial)
        themes.adjustConflicts(initial)

        vim.api.nvim_create_autocmd('ColorScheme', {
            desc = 'Make necessary adjustments to the selected colorscheme.',
            group = vim.api.nvim_create_augroup('color-scheme-background-removal', { clear = true }),
            callback = function(args)
                themes.adjustConflicts(args.match)
            end,
        })
    end,
}
