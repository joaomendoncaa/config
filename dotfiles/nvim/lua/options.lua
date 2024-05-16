local o = vim.opt
local g = vim.g
local autocmd = vim.api.nvim_create_autocmd

g.mapleader = ' ' -- set leader key to space
g.maplocalleader = ' '
g.have_nerd_font = true -- signal for plugins that nerd font is enabled

-- silence nvim-navic errors/warnings
-- TODO: fix tsserver/typescript-tools conflict instead of silencing errors
g.navic_silence = true

-- skip backwards compatibility routines and speed up loading
-- SEE: https://github.com/JoosepAlviste/nvim-ts-context-commentstring?tab=readme-ov-file#getting-started
g.skip_ts_context_commentstring_module = true

o.termguicolors = true -- 24 bit color
o.laststatus = 0 -- remove satusline
o.signcolumn = 'yes' -- keep signcolumn on by default
o.cursorline = true -- show which line your cursor is on
o.number = true -- sign numbers column
o.relativenumber = true
o.fillchars = { eob = ' ' } -- remove tilda from column on blank lines
o.mouse = 'a' -- enable mouse
o.showmode = false -- don't show the mode
o.clipboard = 'unnamedplus' -- sync clipboard between OS and Neovim.
o.breakindent = true -- enable break indent
o.undofile = true -- save undo history
o.ignorecase = true -- case-insensitive searching UNLESS \C or capital in search
o.smartcase = true
o.updatetime = 250 -- decrease update time
o.splitright = true -- configure how new splits should be opened
o.splitbelow = true
o.inccommand = 'split' -- preview substitutions live
o.scrolloff = 10 -- minimal number of screen lines to keep above and below the cursor.
o.hlsearch = true -- set highlight on search, but clear on pressing <Esc> in normal mode
o.completeopt = { 'menu,menuone,noselect' }
o.shortmess:append 'c' -- :help shortmess

-- highlight when yanking characters
autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('highlight-yank', { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})
