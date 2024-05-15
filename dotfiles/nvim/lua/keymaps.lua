local keymap = vim.keymap.set

keymap('n', '<Esc>', '<cmd>nohlsearch<CR>', { desc = '[E]scape from search highlights.' })

keymap('n', '[d', vim.diagnostic.goto_prev, { desc = 'Go to previous [D]iagnostic message.' })
keymap('n', ']d', vim.diagnostic.goto_next, { desc = 'Go to next [D]iagnostic message.' })
keymap('n', '<leader>Q', vim.diagnostic.open_float, { desc = '[Q]uickly show diagnostic error messages.' })
keymap('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list.' })

keymap('x', 'p', [["_dP]], { desc = '[P]aste but preserve the clipboard buffer.' })
