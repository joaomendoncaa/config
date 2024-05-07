return {
  'Wansmer/treesj',
  dependencies = { 'nvim-treesitter/nvim-treesitter' },
  config = function()
    require('treesj').setup {
      use_default_keymaps = false,
    }

    vim.keymap.set('n', '<leader>m', require('treesj').toggle, { desc = 'Toggle block split.' })

    vim.keymap.set('n', '<leader>M', function()
      require('treesj').toggle { split = { recursive = true } }
    end, { desc = 'Toggle block split recursively.' })
  end,
}
