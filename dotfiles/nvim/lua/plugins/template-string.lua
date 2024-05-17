return {
    -- Neovim plugin to automatic change normal string to template string in JS like languages.
    -- SEE: https://github.com/axelvc/template-string.nvim
    'axelvc/template-string.nvim',

    event = 'VeryLazy',

    config = function()
        require('template-string').setup()
    end,
}
