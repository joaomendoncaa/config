return {
    { -- Poimandres colorscheme for Neovim written in Lua.
        -- SEE: https://github.com/olivercederborg/poimandres.nvim
        'olivercederborg/poimandres.nvim',

        priority = 1000,

        config = function()
            local poimandres = require 'poimandres'
            local themes = require 'utils.themes'
            local theme = vim.env.NVIM_THEME or 'default'
            local cmd = vim.cmd

            poimandres.setup {
                dim_nc_background = true,
                disable_background = true,
                disable_float_background = true,
            }

            cmd.colorscheme(theme)
            themes.adjustConflicts(theme)
        end,
    },

    {
        -- Lua port of the most famous vim colorscheme.
        -- SEE: https://github.com/ellisonleao/gruvbox.nvim
        'ellisonleao/gruvbox.nvim',

        priotity = 1000,

        config = function()
            local gruvbox = require 'gruvbox'
            local themes = require 'utils.themes'
            local theme = vim.env.NVIM_THEME or 'default'
            local cmd = vim.cmd

            gruvbox.setup {}

            cmd.colorscheme(theme)
            themes.adjustConflicts(theme)
        end,
    },
}
