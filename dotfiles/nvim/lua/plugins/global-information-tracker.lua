return {
    {
        -- Plugin for calling lazygit from within neovim.
        -- SEE: https://github.com/kdheepak/lazygit.nvim
        'kdheepak/lazygit.nvim',

        cmd = {
            'LazyGit',
            'LazyGitConfig',
            'LazyGitCurrentFile',
            'LazyGitFilter',
            'LazyGitFilterCurrentFile',
        },

        init = function()
            local g = vim.g

            vim.keymap.set('n', '<leader>lg', '<CMD>LazyGit<CR>', { desc = 'Launch [L]azy[G]it.' })

            g.lazygit_floating_window_scaling_factor = 0.775
            g.lazygit_floating_window_use_plenary = 0
            g.lazygit_floating_window_border_chars = { '', '', '', '', '', '', '', '' }
            g.lazygit_floating_window_winblend = 0
        end,
    },

    {
        -- Git integration for buffers.
        -- SEE: https://github.com/lewis6991/gitsigns.nvim
        'lewis6991/gitsigns.nvim',

        event = 'VeryLazy',

        config = function()
            require('gitsigns').setup {
                signs = {
                    add = { text = '+' },
                    change = { text = '~' },
                    delete = { text = '_' },
                    topdelete = { text = '‾' },
                    changedelete = { text = '~' },
                },
            }
        end,
    },
}
