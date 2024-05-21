return {
    {
        -- Neovim file explorer: edit your filesystem like a buffer.
        -- SEE: https://github.com/stevearc/oil.nvim
        'stevearc/oil.nvim',

        event = 'VeryLazy',

        dependencies = {
            { 'nvim-tree/nvim-web-devicons', enabled = vim.g._NERD_FONT },
        },

        config = function()
            require('oil').setup {
                keymaps = {
                    ['<a-h>'] = 'actions.parent',
                    ['<a-l>'] = 'actions.select',
                },
                default_file_explorer = true,
                view_options = {
                    show_hidden = true,
                    show_ignored = true,
                },
                columns = {
                    'icon',
                },
                win_options = {
                    signcolumn = 'yes:2',
                },
                delete_to_trash = true,
                skip_confirm_for_simple_edits = true,
            }

            vim.keymap.set('n', '-', '<CMD>Oil<CR>', { desc = 'Open file explorer with oil.nvim in cwd.' })
        end,
    },

    {
        -- Adds the git status for each file on the buffer.
        -- SEE: https://github.com/refractalize/oil-git-status.nvim
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
