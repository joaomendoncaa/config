local key = vim.keymap

key.set('n', '<Esc>', '<cmd>nohlsearch<CR>', { desc = '[E]scape from search highlights.' })

key.set('n', '[d', vim.diagnostic.goto_prev, { desc = 'Go to previous [D]iagnostic message.' })
key.set('n', ']d', vim.diagnostic.goto_next, { desc = 'Go to next [D]iagnostic message.' })
key.set('n', '<leader>e', vim.diagnostic.open_float, { desc = 'Show diagnostic [E]rror messages' })
key.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })

-- disable arrow keys in normal mode
-- TODO: remove this thing whenever possible
key.set('', '<left>', '<cmd>echo "USE H TO MOVE!!"<CR>')
key.set('', '<right>', '<cmd>echo "USE L TO MOVE!!"<CR>')
key.set('', '<up>', '<cmd>echo "USE K TO MOVE!!"<CR>')
key.set('', '<down>', '<cmd>echo "USE J TO MOVE!!"<CR>')

key.set('n', '<C-e>', '<CMD>Oil<CR>', { desc = '[E]xplore parent directory.' })

key.set({ 'n', 'i', 'v' }, '<C-s>', '<CMD>w<CR>', { desc = '[S]ave current buffer.' })
key.set({ 'n', 'i', 'v' }, '<C-S>', '<CMD>wa<CR>', { desc = '[S]ave all buffers.' })
key.set({ 'n', 'i', 'v' }, '<C-q>', '<CMD>wqa<CR>', { desc = '[S]ave all buffers and [Q]uit nvim.' })

key.set('x', 'p', [["_dP]], { desc = '[P]aste but preserve the clipboard buffer.' })
