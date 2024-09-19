return {
    -- Neovim plugin to manage the file system and other tree like structures.
    -- SEE: https://github.com/nvim-neo-tree/neo-tree.nvim
    -- 'nvim-neo-tree/neo-tree.nvim',
    dir = '~/lab/neo-tree.nvim',

    -- version = '*',
    dependencies = {
        'nvim-lua/plenary.nvim',
        'MunifTanjim/nui.nvim',
        'nvim-tree/nvim-web-devicons',
    },

    cmd = 'Neotree',
    keys = {
        { '<leader>e', ':Neotree reveal<CR>', desc = 'NeoTree reveal', silent = true },
    },

    config = function()
        require('neo-tree').setup {
            close_if_last_window = true,

            window = {
                mappings = {
                    ['P'] = { 'toggle_preview', config = { title = 'Preview' } },
                },
            },

            filesystem = {
                window = {
                    position = 'right',
                    mappings = {
                        ['h'] = 'close_node',
                        ['l'] = 'open',
                    },
                },
            },
        }
    end,
}
