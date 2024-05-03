local key = vim.keymap

key.set('n', '<Esc>', '<cmd>nohlsearch<CR>', { desc = '[E]scape from search highlights.' })

key.set('n', '[d', vim.diagnostic.goto_prev, { desc = 'Go to previous [D]iagnostic message.' })
key.set('n', ']d', vim.diagnostic.goto_next, { desc = 'Go to next [D]iagnostic message.' })
key.set('n', '<leader>e', vim.diagnostic.open_float, { desc = 'Show diagnostic [E]rror messages' })
key.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })

-- disable arrow keys in all modes + show an error on the command line
key.set({ 'n', 'i', 'v' }, '<left>', '<cmd>echohl ErrorMsg | echo "USE H TO MOVE!!" | echohl None<CR>')
key.set({ 'n', 'i', 'v' }, '<right>', '<cmd>echohl ErrorMsg | echo "USE L TO MOVE!!" | echohl None<CR>')
key.set({ 'n', 'i', 'v' }, '<up>', '<cmd>echohl ErrorMsg | echo "USE K TO MOVE!!" | echohl None<CR>')
key.set({ 'n', 'i', 'v' }, '<down>', '<cmd>echohl ErrorMsg | echo "USE J TO MOVE!!" | echohl None<CR>')

key.set('n', '<C-e>', '<CMD>Oil<CR>', { desc = '[E]xplore parent directory.' })

key.set({ 'n', 'i', 'v' }, '<C-s>', '<CMD>w<CR>', { desc = '[S]ave current buffer.' })
key.set({ 'n', 'i', 'v' }, '<C-S>', '<CMD>wa<CR>', { desc = '[S]ave all buffers.' })
key.set({ 'n', 'i', 'v' }, '<C-q>', '<CMD>w | bd<CR>', { desc = '[S]ave buffer and [Q]uit it.' })
key.set({ 'n', 'i', 'v' }, '<C-S-q>', '<CMD>wqa<CR>', { desc = '[S]ave all buffers and [Q]uit nvim.' })

key.set('x', 'p', [["_dP]], { desc = '[P]aste but preserve the clipboard buffer.' })
