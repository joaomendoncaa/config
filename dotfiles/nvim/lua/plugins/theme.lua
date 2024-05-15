return {
  {
    -- Poimandres colorscheme for Neovim written in Lua.
    -- SEE: https://github.com/olivercederborg/poimandres.nvim
    'olivercederborg/poimandres.nvim',

    config = function()
      require('poimandres').setup {
        dim_nc_background = true,
        disable_background = true,
        disable_float_background = true,
      }

      vim.cmd.colorscheme 'poimandres'

      vim.cmd.hi 'Normal guibg=none ctermbg=none'
      vim.cmd.hi 'Comment gui=none'
      vim.cmd.hi 'LspReferenceWrite guibg=none'
      vim.cmd.hi 'LspReferenceText guibg=none'
      vim.cmd.hi 'LspReferenceRead guibg=none'
    end,
  },

  {
    -- The fastest Neovim colorizer.
    -- SEE: https://github.com/norcalli/nvim-colorizer.lua
    'norcalli/nvim-colorizer.lua',

    config = function()
      require('colorizer').setup(nil, { css = true })
    end,
  },
}
