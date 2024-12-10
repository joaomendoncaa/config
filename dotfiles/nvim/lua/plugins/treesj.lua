return {
    -- Neovim plugin for splitting/joining blocks of code
    -- SEE: https://github.com/Wansmer/treesj
    'Wansmer/treesj',

    keys = {
        {
            '<leader>m',
            "<CMD>lua require('treesj').toggle()<CR>",
            { desc = 'Toggle block split.' },
        },
        {
            '<leader>m',
            "<CMD>lua require('treesj').toggle { split = { recursive = true } }<CR>",
            { desc = 'Toggle block split recursively.' },
        },
    },

    dependencies = { 'nvim-treesitter/nvim-treesitter' },

    opts = {
        use_default_keymaps = false,
        max_join_length = 120000,
    },
}
