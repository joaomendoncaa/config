-- Install lazyvim plugin manager.
-- SEE: https://www.lazyvim.org/configuration/lazy.nvim

local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
local lazyrepo = 'https://github.com/folke/lazy.nvim.git'

vim.fn.system {
    'git',
    'clone',
    '--filter=blob:none',
    '--branch=stable',
    lazyrepo,
    lazypath,
}

---@diagnostic disable-next-line: undefined-field
vim.opt.rtp:prepend(lazypath)
