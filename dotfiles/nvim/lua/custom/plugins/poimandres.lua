return {
  {
    -- If you want to see what colorschemes are already installed, you can use `:Telescope colorscheme`
    'olivercederborg/poimandres.nvim',
    priority = 1000,
    config = function()
      require('poimandres').setup {
        dim_nc_background = true, -- dim 'non-current' window backgrounds
        disable_background = true, -- disable background
        disable_float_background = true, -- disable background for floats
      }
    end,
    init = function()
      vim.cmd.colorscheme 'poimandres'

      -- Set the background color to transparent
      vim.cmd [[highlight Normal guibg=none ctermbg=none]]

      vim.cmd.hi 'Comment gui=none'
      vim.cmd.hi 'LspReferenceWrite guibg=none'
      vim.cmd.hi 'LspReferenceText guibg=none'
      vim.cmd.hi 'LspReferenceRead guibg=none'
    end,
  },
}
