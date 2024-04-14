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

      -- You can configure highlights by doing something like
      vim.cmd.hi 'Comment gui=none'

      -- Set the background color to transparent
      vim.cmd [[highlight Normal guibg=none ctermbg=none]]
    end,
  },
}
