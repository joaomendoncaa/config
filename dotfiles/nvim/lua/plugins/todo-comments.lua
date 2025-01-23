return {
    'folke/todo-comments.nvim',

    event = 'VeryLazy',

    dependencies = {
        'nvim-lua/plenary.nvim',
    },

    opts = {
        signs = true,
        keywords = {
            NOTE = { alt = { 'INFO', 'SEE' } },
        },
    },
}
