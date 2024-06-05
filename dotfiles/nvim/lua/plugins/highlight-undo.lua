return {
    -- Highlight changed text after Undo / Redo operations
    -- SEE: https://github.com/tzachar/highlight-undo.nvim
    'tzachar/highlight-undo.nvim',

    event = 'VeryLazy',

    config = function()
        require('highlight-undo').setup()
    end,
}
