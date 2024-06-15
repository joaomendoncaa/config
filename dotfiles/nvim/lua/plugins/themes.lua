local themes = require 'utils.themes'
local theme = vim.env.NVIM_THEME or 'default'

return {
    {
        -- Poimandres colorscheme for Neovim written in Lua.
        -- SEE: https://github.com/olivercederborg/poimandres.nvim
        'olivercederborg/poimandres.nvim',

        priority = 1000,

        config = function()
            local plugin = require 'poimandres'

            plugin.setup {
                dim_nc_background = true,
                disable_background = true,
                disable_float_background = true,
            }

            themes.update(theme)
        end,
    },

    {
        -- Lua port of the most famous vim colorscheme.
        -- SEE: https://github.com/ellisonleao/gruvbox.nvim
        'ellisonleao/gruvbox.nvim',

        priotity = 1000,

        config = function()
            local plugin = require 'gruvbox'

            plugin.setup {}

            themes.update(theme)
        end,
    },

    {
        -- A delightful mostly gray scale colorscheme thats soft on the eyes, and supports heaps of neovim plugins.
        -- SEE: https://github.com/slugbyte/lackluster.nvim
        'slugbyte/lackluster.nvim',

        priority = 1000,

        config = function()
            local plugin = require 'lackluster'

            plugin.setup {
                tweek_background = {
                    normal = 'none',
                    telescope = 'none',
                    menu = 'none',
                    popup = 'none',
                },
            }

            themes.update(theme)
        end,
    },

    {
        -- Remixed Kanagawa colourscheme with muted colors. For Neovim.
        -- SEE: https://github.com/sho-87/kanagawa-paper.nvim
        'sho-87/kanagawa-paper.nvim',

        priority = 1000,

        config = function()
            local plugin = require 'kanagawa-paper'

            plugin.setup {
                transparent = true,
                dimInactive = true,
            }

            themes.update(theme)
        end,
    },
}
