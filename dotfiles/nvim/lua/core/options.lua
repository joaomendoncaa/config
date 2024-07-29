-- Nvim globals, options and auto commands.

local strings = require 'utils.strings'
local commands = require 'utils.commands'

local o = vim.opt
local g = vim.g

local toggle_wrap = function()
    vim.cmd 'set wrap!'
end

local buffer_delete = function()
    vim.cmd 'call delete(expand("%")) | bdelete!'
end

local auto_highlight_yank = function()
    vim.highlight.on_yank()
end

local auto_greeter = function()
    if not require('utils.flags').isOne(vim.env.NVIM_PERF) then
        print(string.format('󱐋 %s', vim.fn.getcwd()))
        return
    end

    local stats = require('lazy').stats()
    local title = string.format('%d/%d plugins loaded in %d ms', stats.loaded, stats.count, stats.startuptime)
    local subtitle =
        string.format('[ LazyStart = %d ms | LazyDone = %d ms | UIEnter = %d ms ]', stats.times.LazyStart, stats.times.LazyDone, stats.times.UIEnter)

    local perf_log = strings.truncateChunks({
        { '󱐋', '@function' },
        { ' ' },
        { title },
        { ' ' },
        { subtitle, '@comment' },
    }, {
        length = vim.o.columns / 2,
        separator = '...',
        separator_hg = '@comment',
    })

    vim.api.nvim_echo(perf_log, true, {})
end

local auto_colorscheme = function(args)
    if args.match then
        require('utils.themes').update(args.match)
    end
end

-- flag plugins that there's a nerd font installed
g.NVIM_NERD_FONT = true

g.mapleader = ' '
g.maplocalleader = ' '

o.clipboard = 'unnamedplus'
o.termguicolors = true
o.laststatus = 0
o.statusline = '%#StatusLine#' .. string.rep(' ', vim.api.nvim_win_get_width(0)) .. '%#StatusLineNC#'
o.signcolumn = 'yes'
o.cursorline = true
o.number = true
o.relativenumber = true
o.fillchars = { eob = ' ' }
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
o.whichwrap = 'lh'
o.wrap = false
o.conceallevel = 0

commands.user('ToggleWrap', toggle_wrap)

commands.user('BufferDelete', buffer_delete)

commands.auto({ 'TextYankPost' }, {
    callback = auto_highlight_yank,
})

commands.auto({ 'User' }, {
    pattern = 'LazyVimStarted',
    callback = auto_greeter,
})

commands.auto({ 'ColorScheme' }, {
    callback = auto_colorscheme,
})
