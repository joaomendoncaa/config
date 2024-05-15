return {
  -- Neovim plugin for splitting/joining blocks of code
  -- SEE: https://github.com/Wansmer/treesj
  'Wansmer/treesj',

  event = 'BufEnter',

  dependencies = { 'nvim-treesitter/nvim-treesitter' },

  config = function()
    require('treesj').setup {
      use_default_keymaps = false,
      max_join_length = 10000000,
    }

    vim.keymap.set('n', '<leader>m', require('treesj').toggle, { desc = 'Toggle block split.' })

    vim.keymap.set('n', '<leader>M', function()
      require('treesj').toggle { split = { recursive = true } }
    end, { desc = 'Toggle block split recursively.' })
  end,
}
