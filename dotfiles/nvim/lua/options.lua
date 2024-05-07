local opt = vim.opt
local g = vim.g
local autocmd = vim.api.nvim_create_autocmd

-- set leader key to space
g.mapleader = ' '
g.maplocalleader = ' '

-- enable nerd font
g.have_nerd_font = true

-- silence nvim-navic errors/warnings
-- TODO: fix tsserver/typescript-tools conflict instead of silencing errors
g.navic_silence = true

-- skip backwards compatibility routines and speed up loading
-- SEE: https://github.com/JoosepAlviste/nvim-ts-context-commentstring?tab=readme-ov-file#getting-started
g.skip_ts_context_commentstring_module = true

-- remove satusline
opt.laststatus = 0

-- make line numbers default
opt.number = true
opt.relativenumber = true

-- remove tilda from column on blank lines
opt.fillchars = { eob = ' ' }

-- enable mouse mode, can be useful for resizing splits for example!
opt.mouse = 'a'

-- don't show the mode, since it's already in status line
opt.showmode = false

-- sync clipboard between OS and Neovim.
opt.clipboard = 'unnamedplus'

-- enable break indent
opt.breakindent = true

-- save undo history
opt.undofile = true

-- case-insensitive searching UNLESS \C or capital in search
opt.ignorecase = true
opt.smartcase = true

-- keep signcolumn on by default
opt.signcolumn = 'yes'

-- decrease update time
opt.updatetime = 250

-- decrease mapped sequence wait time
-- displays which-key popup sooner
opt.timeoutlen = 300

-- configure how new splits should be opened
opt.splitright = true
opt.splitbelow = true

-- Preview substitutions live, as you type!
opt.inccommand = 'split'

-- show which line your cursor is on
opt.cursorline = true

-- minimal number of screen lines to keep above and below the cursor.
opt.scrolloff = 10

-- set highlight on search, but clear on pressing <Esc> in normal mode
opt.hlsearch = true

-- highlight when yanking characters
autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('highlight-yank', { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})
