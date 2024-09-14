return {
    -- Auto-Focusing and Auto-Resizing Splits/Windows for Neovim written in Lua. A full suite of window management enhancements. Vim splits on steroids!
    -- SEE: https://github.com/nvim-focus/focus.nvim
    'nvim-focus/focus.nvim',

    version = '*',

    config = function()
        require('focus').setup {
            enable = true,
            commands = true,
            autoresize = {
                enable = true,
                width = 0,
                height = 0,
                minwidth = 0,
                minheight = 0,
                height_quickfix = 10,
            },
            split = {
                bufnew = false,
                tmux = true,
            },
            ui = {
                number = false,
                relativenumber = false,
                hybridnumber = false,
                absolutenumber_unfocussed = false,

                cursorline = true,
                cursorcolumn = false,
                colorcolumn = {
                    enable = false,
                    list = '+1',
                },
                signcolumn = true,
                winhighlight = false,
            },
        }
    end,
}
