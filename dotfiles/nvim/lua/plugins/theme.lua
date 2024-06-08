local themes = require 'utils.themes'
local theme = vim.env.NVIM_THEME or 'default'
local cmd = vim.cmd

return {
    {
        -- Poimandres colorscheme for Neovim written in Lua.
        -- SEE: https://github.com/olivercederborg/poimandres.nvim
        'olivercederborg/poimandres.nvim',

        priority = 1000,

        config = function()
            local poimandres = require 'poimandres'

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

            gruvbox.setup {}

            cmd.colorscheme(theme)
            themes.adjustConflicts(theme)
        end,
    },

    {
        -- A delightful mostly gray scale colorscheme thats soft on the eyes, and supports heaps of neovim plugins.
        -- SEE: https://github.com/slugbyte/lackluster.nvim
        'slugbyte/lackluster.nvim',

        priority = 1000,

        config = function()
            local lackluster = require 'lackluster'

            lackluster.setup {
                tweek_background = {
                    normal = 'none',
                    telescope = 'none',
                    menu = 'none',
                    popup = 'none',
                },
            }

            cmd.colorscheme(theme)
            themes.adjustConflicts(theme)
        end,
    },
}
