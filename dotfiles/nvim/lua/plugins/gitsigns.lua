return {
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
}
