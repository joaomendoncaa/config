return {
    {
        'stevearc/oil.nvim',

        event = 'VeryLazy',

        dependencies = {
            { 'nvim-tree/nvim-web-devicons', enabled = vim.g.NVIM_NERD_FONT },
        },

        config = function()
            local plugin = require 'oil'

            local key = require('utils.functions').key

            key('n', '-', '<CMD>Oil<CR>', 'Open file explorer with oil.nvim in cwd.')

            plugin.setup {
                default_file_explorer = true,
                delete_to_trash = true,
                skip_confirm_for_simple_edits = true,
                columns = {
                    'icon',
                },
                keymaps = {
                    h = 'actions.parent',
                    l = 'actions.select',
                },
                view_options = {
                    show_hidden = true,
                    show_ignored = true,
                    is_always_hidden = function(n, _)
                        return n == '..' or n == '.git'
                    end,
                },
                win_options = {
                    signcolumn = 'yes:2',
                    wrap = true,
                },
            }
        end,
    },

    {
        'refractalize/oil-git-status.nvim',

        event = 'VeryLazy',

        dependencies = {
            'stevearc/oil.nvim',
        },

        config = function()
            require('oil-git-status').setup {}
        end,
    },
}
