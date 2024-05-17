-- Install lazyvim plugin manager and setup all plugins.
-- SEE: https://www.lazyvim.org/configuration/lazy.nvim

local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
local lazyopts = {
    change_detection = { notify = false },
    performance = {
        cache = { enabled = true },
        rtp = {
            disabled_plugins = {
                'netrwPlugin',
                'gzip',
                'tarPlugin',
                'tohtml',
                'tutor',
                'zipPlugin',
            },
        },
    },
}

vim.fn.system { 'git', 'clone', '--filter=blob:none', '--branch=stable', lazyrepo, lazypath }

vim.opt.rtp:prepend(lazypath)

require('lazy').setup('plugins', lazyopts)
