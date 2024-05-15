return {
  -- Highlight, list and search todo comments in your projects.
  -- SEE: https://github.com/folke/todo-comments.nvim
  'folke/todo-comments.nvim',

  event = 'VimEnter',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-telescope/telescope.nvim',
  },

  config = function()
    require('todo-comments').setup {
      signs = true,
      keywords = {
        NOTE = { alt = { 'INFO', 'SEE' } },
      },
    }

    vim.keymap.set('n', '<leader>st', '<CMD>TodoTelescope<CR>', { desc = '[S]earch all [T]odos in workspace.' })
  end,
}
