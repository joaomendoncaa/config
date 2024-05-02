return {
  'utilyre/barbecue.nvim',
  name = 'barbecue',
  version = '*',
  dependencies = {
    'SmiteshP/nvim-navic',
    'nvim-tree/nvim-web-devicons',
  },
  config = function()
    require('barbecue').setup {
      -- prevent barbecue from updating itself automatically
      create_autocmd = false,
      -- replace icon with modified flag
      show_modified = true,
    }

    -- custom update for barbecue to be more performant when moving the cursor around
    vim.api.nvim_create_autocmd({
      'WinScrolled',
      'BufWinEnter',
      'CursorHold',
      'InsertLeave',

      -- `show_modified` to `true`
      'BufModifiedSet',
    }, {
      group = vim.api.nvim_create_augroup('barbecue.updater', {}),
      callback = function()
        require('barbecue.ui').update()
      end,
    })
  end,
}
