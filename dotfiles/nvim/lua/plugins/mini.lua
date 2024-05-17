return {
    -- Library of 35+ independent Lua modules improving overall Neovim (version 0.7 and higher) experience with minimal effort.
    -- SEE: https://github.com/echasnovski/mini.nvim
    'echasnovski/mini.nvim',

    config = function()
        -- better around/inside textobjects
        --
        --  - va)  - [V]isually select [A]round [)]paren
        --  - yinq - [Y]ank [I]nside [N]ext [']quote
        --  - ci'  - [C]hange [I]nside [']quote
        require('mini.ai').setup { n_lines = 500 }

        -- add/delete/replace surroundings (brackets, quotes, etc.)
        --
        -- - saiw) - [S]urround [A]dd [I]nner [W]ord [)]Pareninit lua
        -- - sd'   - [S]urround [D]elete [']quotes
        -- - sr)'  - [S]urround [R]eplace [)] [']
        require('mini.surround').setup()
    end,
}
