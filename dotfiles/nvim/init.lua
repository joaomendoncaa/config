-- set globals and options for nvim
require 'options'

-- define all things keymaps
require 'keymaps'

-- install the lazyvim plugin manager
-- see: https://www.lazyvim.org/configuration/lazy.nvim
require 'lazyvim'

-- load all plugins with lazyvim
require('lazy').setup {
  'tpope/vim-sleuth',
  'mg979/vim-visual-multi',

  -- import all .lua plugins at lua/plugins
  { import = 'plugins' },
}

-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et
