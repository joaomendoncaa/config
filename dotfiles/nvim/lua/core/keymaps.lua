-- most keymaps are directly in their related plugin tables
-- this file is for "global" keymaps unrelated to any plugin

local key = require('utils.functions').key

key('n', '<Esc>', '<cmd>nohlsearch<CR>', '[E]scape from search highlights.')

key('n', '<leader>q', vim.diagnostic.open_float, '[Q]uickly show diagnostic error messages')
key('n', '<leader>Q', vim.diagnostic.setloclist, 'Open diagnostic [Q]uickfix list')

key('x', 'p', [["_dP]], '[P]aste but preserve the clipboard buffer')

key('n', 'j', 'gj', '[J] Move down even in wrapped lines')
key('n', 'k', 'gk', '[K] Move up even in wrapped lines')

key({ 'n', 'i', 'v' }, '<C-s>', '<CMD>w<CR>', '[S]ave the current file')
key({ 'n', 'i', 'v' }, '<C-q>', '<CMD>wqa<CR>', 'Save all files and [Q]uit')

key('n', '<C-M-h>', function()
    if vim.fn.winnr '$' > 1 then
        return ':vertical resize -3<CR>'
    end
    return vim.fn.system 'tmux resize-pane -L 3'
end, { silent = true, expr = true, desc = 'Smart resize left' })

key('n', '<C-M-l>', function()
    if vim.fn.winnr '$' > 1 then
        return ':vertical resize +3<CR>'
    end
    return vim.fn.system 'tmux resize-pane -R 3'
end, { silent = true, expr = true, desc = 'Smart resize right' })

key('n', '<C-M-k>', function()
    if vim.fn.winnr '$' > 1 then
        return ':resize -3<CR>'
    end
    return vim.fn.system 'tmux resize-pane -U 3'
end, { silent = true, expr = true, desc = 'Smart resize up' })

key('n', '<C-M-j>', function()
    if vim.fn.winnr '$' > 1 then
        return ':resize +3<CR>'
    end
    return vim.fn.system 'tmux resize-pane -D 3'
end, { silent = true, expr = true, desc = 'Smart resize down' })
