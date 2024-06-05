-- Nvim globals, options and auto commands.

local o = vim.opt
local g = vim.g
local autocmd = vim.api.nvim_create_autocmd

-- flag plugins that there's a nerd font installed
g._NERD_FONT = true
-- silence nvim-navic errors/warnings
g.navic_silence = true
-- skip backwards compatibility routines and speed up loading
g.skip_ts_context_commentstring_module = true

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

autocmd('TextYankPost', {
    desc = 'Briefly highlight text range when yanking.',
    group = vim.api.nvim_create_augroup('text-yank-post-highlighting', { clear = true }),
    callback = function()
        vim.highlight.on_yank()
    end,
})

autocmd('ColorScheme', {
    desc = 'Make necessary adjustments to the selected colorscheme.',
    group = vim.api.nvim_create_augroup('color-scheme-background-removal', { clear = true }),
    callback = function(args)
        require('utils.themes').adjustConflicts(args.match)
    end,
})

autocmd('User', {
    desc = 'Echo lazy stats into command line on start.',
    pattern = 'LazyVimStarted',
    callback = function()
        if not require('utils.flags').isOne(vim.env.PERF) then
            print(string.format('󱐋 %s', vim.fn.getcwd()))
            return
        end

        local stats = require('lazy').stats()

        vim.api.nvim_echo({
            { '󱐋', '@function' },
            { ' ' },
            { string.format('%d/%d plugins loaded in %d ms', stats.loaded, stats.count, stats.startuptime), '' },
            { ' ' },
            {
                string.format('[ LazyStart = %d ms | LazyDone = %d ms | UIEnter = %d ms ]', stats.times.LazyStart, stats.times.LazyDone, stats.times.UIEnter),
                '@comment',
            },
        }, false, {})
    end,
})
