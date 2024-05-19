return {
    -- Highlight, list and search todo comments in your projects.
    -- SEE: https://github.com/folke/todo-comments.nvim
    'folke/todo-comments.nvim',

    event = 'VeryLazy',

    dependencies = {
        'nvim-lua/plenary.nvim',
        'nvim-telescope/telescope.nvim',
    },

    config = function()
        require('todo-comments').setup {
            signs = true,
            keywords = {
                NOTE = { alt = { 'INFO', 'SEE' } },
            },
        }
    end,
}
