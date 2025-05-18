local RESIZE_STEP = 15

local clipboard = require 'utils.clipboard'

local key = require('utils.functions').key

key('n', '<Esc>', '<cmd>nohlsearch<CR>', '[E]scape from search highlights.')

key('n', '<leader>q', vim.diagnostic.open_float, '[Q]uickly show diagnostic error messages')
key('n', '<leader>Q', vim.diagnostic.setloclist, 'Open diagnostic [Q]uickfix list')

key('n', 'gp', clipboard.replace_with_yanked_and_write, "[G]o replace by [P]asting what's yanked")

key('x', 'p', [["_dP]], '[P]aste but preserve the clipboard buffer')

key('n', 'j', 'gj', '[J] Move down even in wrapped lines')
key('n', 'k', 'gk', '[K] Move up even in wrapped lines')

key('n', 'YY', 'va{Vy', '[Y]ank function')

key({ 'n', 'i', 'v' }, '<C-s>', '<CMD>w<CR>', '[S]ave the current file')
key({ 'n', 'i', 'v' }, '<C-q>', '<CMD>wqa<CR>', 'Save all files and [Q]uit')

key('n', '<C-M-h>', function()
    if vim.fn.winnr '$' > 1 then
        return string.format(':vertical resize -%d<CR>', RESIZE_STEP)
    end
    return vim.fn.system(string.format 'tmux resize-pane -L %d', RESIZE_STEP)
end, { silent = true, expr = true, desc = 'Smart resize left' })

key('n', '<C-M-l>', function()
    if vim.fn.winnr '$' > 1 then
        return string.format(':vertical resize +%d<CR>', RESIZE_STEP)
    end
    return vim.fn.system(string.format 'tmux resize-pane -R %d', RESIZE_STEP)
end, { silent = true, expr = true, desc = 'Smart resize right' })

key('n', '<C-M-k>', function()
    if vim.fn.winnr '$' > 1 then
        return string.format(':resize -%d<CR>', RESIZE_STEP)
    end
    return vim.fn.system(string.format 'tmux resize-pane -U %d', RESIZE_STEP)
end, { silent = true, expr = true, desc = 'Smart resize up' })

key('n', '<C-M-j>', function()
    if vim.fn.winnr '$' > 1 then
        return string.format(':resize +%d<CR>', RESIZE_STEP)
    end
    return vim.fn.system(string.format 'tmux resize-pane -D %d', RESIZE_STEP)
end, { silent = true, expr = true, desc = 'Smart resize down' })
