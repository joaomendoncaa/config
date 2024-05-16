return {
  -- A task runner and job management plugin for Neovim.
  -- SEE: https://github.com/stevearc/overseer.nvim
  'stevearc/overseer.nvim',

  init = function()
    local keymap = vim.keymap.set

    keymap('n', '<leader>tt', '<CMD>OverseerToggle<CR>', { desc = 'Overseer [T]asks [T]oggle.' })
    keymap('n', '<leader>tr', '<CMD>OverseerRun<CR>', { desc = 'Overseer [T]asks [R]un.' })
  end,

  config = function()
    require('overseer').setup {
      task_list = {
        direction = 'bottom',
        default_detail = 1,
      },
    }
  end,
}
