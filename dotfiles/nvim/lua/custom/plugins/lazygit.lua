return {
  {
    'kdheepak/lazygit.nvim',

    cmd = {
      'LazyGit',
      'LazyGitConfig',
      'LazyGitCurrentFile',
      'LazyGitFilter',
      'LazyGitFilterCurrentFile',
    },

    keys = {
      { '<leader>lg', '<cmd>LazyGit<cr>', desc = 'Launch [L]azy[G]it' },
    },

    config = function()
      vim.g.lazygit_floating_window_scaling_factor = 0.5
    end,
  },
}
