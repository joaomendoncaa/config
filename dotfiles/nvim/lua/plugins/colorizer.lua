return {
  -- The fastest Neovim colorizer.
  -- SEE: https://github.com/norcalli/nvim-colorizer.lua
  'norcalli/nvim-colorizer.lua',

  config = function()
    require('colorizer').setup(nil, { css = true })
  end,
}
