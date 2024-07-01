local themes = require 'utils.themes'

local theme = vim.env.NVIM_THEME or 'default'
local priority = 1000

return {
    {
        -- Poimandres colorscheme for Neovim written in Lua.
        -- SEE: https://github.com/olivercederborg/poimandres.nvim
        'olivercederborg/poimandres.nvim',

        priority = priority,

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

        priotity = priority,

        config = function()
            local plugin = require 'gruvbox'

            plugin.setup {}

            themes.update(theme)
        end,
    },

    {
        -- Remixed Kanagawa colourscheme with muted colors. For Neovim.
        -- SEE: https://github.com/sho-87/kanagawa-paper.nvim
        'sho-87/kanagawa-paper.nvim',

        priority = priority,

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
