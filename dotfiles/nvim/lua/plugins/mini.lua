return {
  {
    -- this is a very packed plugin with a lot of utilities
    -- see: https://github.com/echasnovski/mini.nvim
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

      -- jump interatively with labels
      -- SEE: https://github.com/echasnovski/mini.nvim/blob/main/readmes/mini-jump2d.md
      require('mini.jump2d').setup()
    end,
  },
}
