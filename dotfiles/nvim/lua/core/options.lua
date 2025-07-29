local o = vim.opt
local g = vim.g

-- flag plugins that there's a nerd font installed
g.NVIM_NERD_FONT = true

g.mapleader = ' '
g.maplocalleader = ' '

o.swapfile = false
o.clipboard = 'unnamedplus'
o.termguicolors = true
o.laststatus = 0
o.statusline = '%#StatusLine#' .. string.rep(' ', vim.api.nvim_win_get_width(0)) .. '%#StatusLineNC#'
o.signcolumn = 'yes'
o.cursorline = true
o.number = true
o.relativenumber = true
o.mouse = 'a'
o.showmode = false
o.breakindent = true
o.undofile = true
o.ignorecase = true
o.smartcase = true
o.updatetime = 250
o.splitright = true
o.splitbelow = true
o.inccommand = 'split'
o.smoothscroll = true
o.scrolloff = 10
o.hlsearch = true
o.completeopt = { 'menu,menuone,noselect' }
o.shortmess:append 'c'
o.shortmess:append 'I'
o.fillchars:append { eob = ' ' }
o.whichwrap = 'lh'
o.wrap = true
o.conceallevel = 0
o.sessionoptions = 'buffers,curdir,folds,help,tabpages,winsize,terminal'
o.foldcolumn = '0'
o.foldlevel = 99
o.foldlevelstart = 99
o.foldenable = true
o.guicursor = { 'n-v-c-sm:block', 'i-ci-ve:block', 'r-cr-o:block' }
