require 'globals'
require 'options'
require 'keymaps'
require 'lazyvim'

require('lazy').setup {
  'tpope/vim-sleuth',
  'numToStr/Comment.nvim',
  { import = 'custom.plugins' },
}

-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et
