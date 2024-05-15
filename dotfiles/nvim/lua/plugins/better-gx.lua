return {
  -- A better gx command in neovim.
  -- SEE: https://github.com/TobinPalmer/BetterGx.nvim
  'TobinPalmer/BetterGX.nvim',

  lazy = true,

  config = function()
    vim.keymap.set('n', 'gx', '<CMD>lua require("better-gx").BetterGx()<CR>', { desc = 'Open URL under cursor with default browser.' })
  end,
}
