local PRIORITY = 1000

return {
    {
        -- Poimandres colorscheme for Neovim written in Lua.
        -- SEE: https://github.com/olivercederborg/poimandres.nvim
        'olivercederborg/poimandres.nvim',

        priority = PRIORITY,

        config = function()
            local plugin = require 'poimandres'

            plugin.setup {
                dim_nc_background = true,
                disable_background = true,
                disable_float_background = true,
            }
        end,
    },

    {
        -- Lua port of the most famous vim colorscheme.
        -- SEE: https://github.com/ellisonleao/gruvbox.nvim
        'ellisonleao/gruvbox.nvim',

        priotity = PRIORITY,

        config = function()
            local plugin = require 'gruvbox'

            plugin.setup {}
        end,
    },

    {
        -- Remixed Kanagawa colourscheme with muted colors. For Neovim.
        -- SEE: https://github.com/sho-87/kanagawa-paper.nvim
        'sho-87/kanagawa-paper.nvim',

        priority = PRIORITY,

        config = function()
            local plugin = require 'kanagawa-paper'

            plugin.setup {
                transparent = true,
                dimInactive = true,
            }
        end,
    },

    {
        -- Flow is an Nvim color scheme designed for transparent or dark backgrounds.
        -- SEE: https://github.com/0xstepit/flow.nvim
        '0xstepit/flow.nvim',

        priority = PRIORITY,

        config = function()
            local plugin = require 'flow'

            plugin.setup {
                transparent = true,
                fluo_color = 'yellow',
                mode = 'bright',
            }
        end,
    },
}
