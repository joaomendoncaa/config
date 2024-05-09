return {
  'SR-Mystar/yazi.nvim',
  lazy = true,
  cmd = 'Yazi',
  config = function()
    require('yazi').setup {
      size = {
        width = 0.75,
        height = 0.75,
      },
    }
  end,
}
