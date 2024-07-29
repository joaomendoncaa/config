-- most keymaps are directly in their related plugin tables
-- this file is for "global" keymaps unrelated to any plugin

local keymap = vim.keymap.set

keymap('n', '<Esc>', '<cmd>nohlsearch<CR>', { desc = '[E]scape from search highlights.' })

keymap('n', '<leader>q', vim.diagnostic.open_float, { desc = '[Q]uickly show diagnostic error messages.' })
keymap('n', '<leader>Q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list.' })

keymap('x', 'p', [["_dP]], { desc = '[P]aste but preserve the clipboard buffer.' })

keymap('n', 'j', 'gj', { desc = '[J] Move down even in wrapped lines.' })
keymap('n', 'k', 'gk', { desc = '[K] Move up even in wrapped lines.' })
