return {
    -- Library of 35+ independent Lua modules improving overall Neovim (version 0.7 and higher) experience with minimal effort.
    -- SEE: https://github.com/echasnovski/mini.nvim
    'echasnovski/mini.nvim',

    event = 'VeryLazy',

    config = function()
        require('mini.ai').setup { n_lines = 500 }

        require('mini.surround').setup()

        require('mini.jump2d').setup {
            mappings = {
                start_jumping = 'S',
            },
            silent = true,
        }
    end,
}
