return {
  -- A task runner and job management plugin for Neovim.
  -- SEE: https://github.com/stevearc/overseer.nvim
  'stevearc/overseer.nvim',

  config = function()
    require('overseer').setup()
  end,
}
