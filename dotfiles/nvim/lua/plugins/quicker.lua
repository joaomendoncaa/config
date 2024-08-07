return {
    -- Improved UI and workflow for the Neovim quickfix.
    -- https://github.com/stevearc/quicker.nvim
    'stevearc/quicker.nvim',

    event = 'VeryLazy',

    config = function()
        require('quicker').setup()
    end,
}
