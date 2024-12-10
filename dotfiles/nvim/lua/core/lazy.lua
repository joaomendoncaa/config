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

if not vim.uv.fs_stat(lazypath) then
    local out = vim.fn.system {
        'git',
        'clone',
        '--filter=blob:none',
        '--branch=stable',
        lazyrepo,
        lazypath,
    }

    if vim.v.shell_error ~= 0 then
        error('Error cloning lazy.nvim repo: ' .. out)
    end
end

vim.opt.rtp:prepend(lazypath)

require('lazy').setup('plugins', lazyopts)
