return {
  {
    'stevearc/oil.nvim',
    opts = {},
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
      require('oil').setup {
        default_file_explorer = true,
        columns = {
          'icon',
        },
        win_options = {
          signcolumn = 'yes:2',
        },
      }
    end,
  },
  -- Adds the git status for each file on the buffer
  -- see: https://github.com/refractalize/oil-git-status.nvim
  {
    'refractalize/oil-git-status.nvim',
    dependencies = {
      'stevearc/oil.nvim',
    },
    config = function()
      require('oil-git-status').setup {
        show_ignored = true,
      }
    end,
  },
}
