return {
    -- Poimandres colorscheme for Neovim written in Lua.
    -- SEE: https://github.com/olivercederborg/poimandres.nvim
    'olivercederborg/poimandres.nvim',

    priority = 1000,

    config = function()
        local poimandres = require 'poimandres'
        local themes = require 'utils.themes'
        local cmd = vim.cmd

        poimandres.setup {
            dim_nc_background = true,
            disable_background = true,
            disable_float_background = true,
        }

        cmd.colorscheme 'poimandres'

        themes.adjustConflicts(cmd.colorscheme)

        vim.api.nvim_create_autocmd('ColorScheme', {
            desc = 'Make necessary adjustments to the selected colorscheme.',
            group = vim.api.nvim_create_augroup('color-scheme-background-removal', { clear = true }),
            callback = function(args)
                themes.adjustConflicts(args.match)
            end,
        })
    end,
}
