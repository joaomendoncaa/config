-- Nvim globals, options and auto commands.

local o = vim.opt
local g = vim.g
local autocmd = vim.api.nvim_create_autocmd
local usercmd = vim.api.nvim_create_user_command
local strings = require 'utils.strings'

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

o.termguicolors = true
o.laststatus = 0
o.signcolumn = 'yes'
o.cursorline = true
o.number = true
o.relativenumber = true
o.fillchars = { eob = ' ' }
o.mouse = 'a'
o.showmode = false
o.clipboard = 'unnamedplus'
o.breakindent = true
o.undofile = true
o.ignorecase = true
o.smartcase = true
o.updatetime = 250
o.splitright = true
o.splitbelow = true
o.inccommand = 'split'
o.scrolloff = 10
o.hlsearch = true
o.completeopt = { 'menu,menuone,noselect' }
o.shortmess:append 'c'
o.shortmess:append 'I'
o.whichwrap = 'lh'
o.wrap = false
o.conceallevel = 0

vim.api.nvim_create_autocmd({ 'User' }, {
    group = vim.api.nvim_create_augroup('user-lazyvimstarted-greeter', { clear = true }),
    pattern = 'LazyVimStarted',
    callback = auto_greeter,
})

autocmd({ 'TextYankPost' }, {
    desc = 'Briefly highlight text range when yanking.',
    group = vim.api.nvim_create_augroup('text-yank-post-highlighting', { clear = true }),
    callback = auto_highlight_yank,
})

autocmd({ 'ColorScheme' }, {
    desc = 'Make necessary adjustments to the selected colorscheme.',
    group = vim.api.nvim_create_augroup('color-scheme-background-removal', { clear = true }),
    callback = auto_colorscheme,
})

usercmd('ToggleWrap', toggle_wrap, {
    desc = 'Toggle wrapping of lines.',
})

usercmd('BufferDelete', buffer_delete, {
    desc = 'Delete the current file.',
})
