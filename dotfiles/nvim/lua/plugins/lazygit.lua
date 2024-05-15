return {
  -- Plugin for calling lazygit from within neovim.
  -- SEE: https://github.com/kdheepak/lazygit.nvim
  'kdheepak/lazygit.nvim',

  cmd = {
    'LazyGit',
    'LazyGitConfig',
    'LazyGitCurrentFile',
    'LazyGitFilter',
    'LazyGitFilterCurrentFile',
  },

  init = function()
    vim.keymap.set('n', '<leader>lg', '<CMD>LazyGit<CR>', { desc = 'Launch [L]azy[G]it.' })
  end,

  config = function()
    vim.g.lazygit_floating_window_scaling_factor = 0.75
    vim.g.lazygit_floating_window_use_plenary = 0
    vim.g.lazygit_floating_window_border_chars = { '', '', '', '', '', '', '', '' }
    vim.g.lazygit_floating_window_winblend = 0
  end,
}
