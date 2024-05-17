return {
  -- Poimandres colorscheme for Neovim written in Lua.
  -- SEE: https://github.com/olivercederborg/poimandres.nvim
  'olivercederborg/poimandres.nvim',

  priority = 1000,

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

    vim.api.nvim_set_hl(0, 'LazyReasonSource', { fg = '#5de4c7' })
    vim.api.nvim_set_hl(0, 'LazyReasonFt', { fg = '#5de4c7' })

    vim.api.nvim_set_hl(0, 'OverseerPENDING', { fg = '#fffac2' })
    vim.api.nvim_set_hl(0, 'OverseerRUNNING', { fg = '#5de4c7' })
    vim.api.nvim_set_hl(0, 'OverseerCANCELED', { fg = '#f087bd' })
    vim.api.nvim_set_hl(0, 'OverseerSUCCESS', { fg = '#5de4c7' })
    vim.api.nvim_set_hl(0, 'OverseerFAILURE', { fg = '#f087bd' })
    vim.api.nvim_set_hl(0, 'OverseerDISPOSED', { fg = '#d0679d' })
  end,
}
