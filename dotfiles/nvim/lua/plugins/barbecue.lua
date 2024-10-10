return {
    -- A VS Code like winbar for Neovim.
    -- SEE: https://github.com/utilyre/barbecue.nvim
    'utilyre/barbecue.nvim',

    name = 'barbecue',
    version = '*',
    event = 'BufEnter',

    dependencies = {
        'SmiteshP/nvim-navic',
        { 'nvim-tree/nvim-web-devicons', enabled = vim.g.NVIM_NERD_FONT },
    },

    init = function()
        vim.g.navic_silence = true
    end,

    config = function()
        local plugin = require 'barbecue'
        local ui = require 'barbecue.ui'
        local commands = require 'utils.commands'

        -- custom update for barbecue to be more performant when moving the cursor around
        -- SEE: https://github.com/utilyre/barbecue.nvim?tab=readme-ov-file#-recipes
        vim.api.nvim_create_autocmd({
            'WinScrolled',
            'BufWinEnter',
            'CursorHold',
            'InsertLeave',
            'BufModifiedSet',
        }, {
            group = commands.augroup 'barbecue.updater',
            callback = function()
                ui.update()
            end,
        })

        plugin.setup {
            create_autocmd = false,
            show_modified = true,
            theme = {
                normal = { bg = 'none' },
            },
        }
    end,
}
