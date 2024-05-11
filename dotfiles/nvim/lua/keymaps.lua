local keymap = vim.keymap.set

keymap('n', '<Esc>', '<cmd>nohlsearch<CR>', { desc = '[E]scape from search highlights.' })

keymap('n', '[d', vim.diagnostic.goto_prev, { desc = 'Go to previous [D]iagnostic message.' })
keymap('n', ']d', vim.diagnostic.goto_next, { desc = 'Go to next [D]iagnostic message.' })
keymap('n', '<leader>Q', vim.diagnostic.open_float, { desc = '[Q]uickly show diagnostic error messages.' })
keymap('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list.' })

keymap({ 'n', 'i', 'v' }, '<C-s>', '<CMD>w<CR>', { desc = '[S]ave current buffer.' })
keymap({ 'n', 'i', 'v' }, '<C-S>', '<CMD>wa<CR>', { desc = '[S]ave all buffers.' })
keymap({ 'n', 'i', 'v' }, '<C-q>', '<CMD>w | bd<CR>', { desc = '[S]ave buffer and [Q]uit it.' })
keymap({ 'n', 'i', 'v' }, '<C-S-q>', '<CMD>wqa<CR>', { desc = '[S]ave all buffers and [Q]uit nvim.' })

keymap('x', 'p', [["_dP]], { desc = '[P]aste but preserve the clipboard buffer.' })
