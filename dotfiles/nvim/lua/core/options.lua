-- Nvim globals, options and auto commands.

local strings = require 'utils.strings'
local commands = require 'utils.commands'
local themes = require 'utils.themes'

local o = vim.opt
local g = vim.g

local toggle_wrap = function()
    vim.cmd 'set wrap!'
end

local buffer_delete = function()
    vim.cmd 'call delete(expand("%")) | bdelete!'
end

local buffer_messages = function()
    local result = vim.api.nvim_exec2('messages', { output = true })

    vim.cmd 'new'
    vim.api.nvim_buf_set_lines(0, 0, -1, false, vim.split(result.output, '\n'))
    vim.bo.buftype = 'nofile'
    vim.bo.bufhidden = 'wipe'
    vim.bo.swapfile = false
end

local auto_highlight_yank = function()
    vim.highlight.on_yank()
end

local auto_colorscheme = function()
    themes.update()
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

commands.user('ToggleWrap', toggle_wrap)

commands.user('BufferDelete', buffer_delete)

commands.user('BufferMessages', buffer_messages)

commands.auto({ 'TextYankPost' }, {
    callback = auto_highlight_yank,
})

commands.auto({ 'User' }, {
    pattern = 'LazyVimStarted',
    callback = auto_greeter,
})

commands.auto({ 'ColorScheme', 'UIEnter' }, {
    callback = auto_colorscheme,
})
