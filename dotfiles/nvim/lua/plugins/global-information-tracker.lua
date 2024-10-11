local g = vim.g
local keymap = vim.keymap.set

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
            keymap('n', '<leader>gl', '<CMD>LazyGit<CR>', { desc = '[G]it: Launch [L]azyGit.' })
            keymap('n', '<leader>grv', '<cmd>silent! !gh repo view --web<CR>', { desc = '[G]it: [R]epository [V]iew.' })

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
            local plugin = require 'gitsigns'

            keymap({ 'n', 'v' }, '<leader>ghp', '<CMD>Gitsigns preview_hunk_inline<CR>', { desc = '[G]it: [H]unk [P]review.' })
            keymap({ 'n', 'v' }, '<leader>ghr', '<CMD>Gitsigns reset_hunk<CR>', { desc = '[G]it: [H]unk [R]eset.' })

            plugin.setup {
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

    {
        -- Neovim plugin that allows you to create a Github Gist from the current file.
        -- SEE: https://github.com/Rawnly/gist.nvim
        'Rawnly/gist.nvim',
        cmd = { 'GistCreate', 'GistCreateFromFile', 'GistsList' },
        config = true,
    },

    {
        -- `GistsList` opens the selected gif in a terminal buffer,
        -- nvim-unception uses neovim remote rpc functionality to open the gist in an actual buffer
        -- and prevents neovim buffer inception
        -- SEE: https://github.com/samjwill/nvim-unception
        'samjwill/nvim-unception',

        lazy = false,

        init = function()
            vim.g.unception_block_while_host_edits = true
        end,
    },
}
