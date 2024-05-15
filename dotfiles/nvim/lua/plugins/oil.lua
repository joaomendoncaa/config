return {
  {
    'stevearc/oil.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
      require('oil').setup {
        keymaps = {
          ['<a-h>'] = 'actions.parent',
          ['<a-l>'] = 'actions.select',
        },
        default_file_explorer = true,
        view_options = {
          show_hidden = true,
        },
        columns = {
          'icon',
        },
        win_options = {
          signcolumn = 'yes:2',
        },
        delete_to_trash = true,
        skip_confirm_for_simple_edits = true,
      }

      vim.keymap.set('n', '-', '<CMD>Oil<CR>', { desc = 'Open file explorer with oil.nvim in cwd.' })
    end,
  },
  -- Adds the git status for each file on the buffer
  -- see: https://github.com/refractalize/oil-git-status.nvim
  {
    'refractalize/oil-git-status.nvim',
    lazy = true,
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
