return {
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

    vim.api.nvim_set_hl(0, 'Normal', { bg = 'none' })
    vim.api.nvim_set_hl(0, 'Comment', { bg = 'none' })
    vim.api.nvim_set_hl(0, 'LspReferenceWrite', { bg = 'none' })
    vim.api.nvim_set_hl(0, 'LspReferenceText', { bg = 'none' })
    vim.api.nvim_set_hl(0, 'LspReferenceRead', { bg = 'none' })
    vim.api.nvim_set_hl(0, 'LazyReasonSource', { fg = '#5de4c7' })
    vim.api.nvim_set_hl(0, 'LazyReasonFt', { fg = '#5de4c7' })
  end,
}
