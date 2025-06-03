local clipboard = require 'utils.clipboard'
local buffers = require 'utils.buffers'

local key = require('utils.misc').key
local f = require('utils.misc').f
local resize_pane = require('utils.misc').resize_pane

key('n', '<Esc>', '<cmd>nohlsearch<CR>', '[E]scape from search highlights.')

key('n', '<leader>q', vim.diagnostic.open_float, '[Q]uickly show diagnostic error messages')
key('n', '<leader>Q', vim.diagnostic.setloclist, 'Open diagnostic [Q]uickfix list')

key('n', 'gp', clipboard.replace_with_yanked_and_write, "[G]o replace by [P]asting what's yanked")

key('x', 'p', [["_dP]], '[P]aste but preserve the clipboard buffer')

key('n', 'j', 'gj', '[J] Move down even in wrapped lines')
key('n', 'k', 'gk', '[K] Move up even in wrapped lines')

key('n', 'YY', 'va{Vy', '[Y]ank function')

key({ 'n', 'i', 'v' }, '<C-s>', '<CMD>w<CR>', '[S]ave the current file')
key({ 'n', 'i', 'v' }, '<C-q>', buffers.handle_save_quit, 'Save file and [Q]uit')

key('n', '<leader>cn', '<cmd>cnext<CR>', '[C]losed item [N]ext in quickfix list')
key('n', '<leader>cp', '<cmd>cprev<CR>', '[C]losed item [P]revious in quickfix list')
key('n', '<leader>cc', '<cmd>cclose<CR>', '[C]lose quickfix window')

key('n', '<C-M-h>', f(resize_pane, 'left', 15), { expr = true, silent = true, desc = 'Smart resize left' })
key('n', '<C-M-l>', f(resize_pane, 'right', 15), { expr = true, silent = true, desc = 'Smart resize right' })
key('n', '<C-M-k>', f(resize_pane, 'up', 15), { expr = true, silent = true, desc = 'Smart resize up' })
key('n', '<C-M-j>', f(resize_pane, 'down', 15), { expr = true, silent = true, desc = 'Smart resize down' })
