local opt = vim.opt
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

opt.termguicolors = true -- 24 bit color
opt.laststatus = 0 -- remove satusline
opt.signcolumn = 'yes' -- keep signcolumn on by default
opt.cursorline = true -- show which line your cursor is on
opt.number = true -- sign numbers column
opt.relativenumber = true
opt.fillchars = { eob = ' ' } -- remove tilda from column on blank lines
opt.mouse = 'a' -- enable mouse
opt.showmode = false -- don't show the mode
opt.clipboard = 'unnamedplus' -- sync clipboard between OS and Neovim.
opt.breakindent = true -- enable break indent
opt.undofile = true -- save undo history
opt.ignorecase = true -- case-insensitive searching UNLESS \C or capital in search
opt.smartcase = true
opt.updatetime = 250 -- decrease update time
opt.splitright = true -- configure how new splits should be opened
opt.splitbelow = true
opt.inccommand = 'split' -- preview substitutions live
opt.scrolloff = 10 -- minimal number of screen lines to keep above and below the cursor.
opt.hlsearch = true -- set highlight on search, but clear on pressing <Esc> in normal mode

-- highlight when yanking characters
autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('highlight-yank', { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})
