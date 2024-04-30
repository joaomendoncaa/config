local key = vim.keymap

key.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- diagnostics
key.set('n', '[d', vim.diagnostic.goto_prev, { desc = 'Go to previous [D]iagnostic message' })
key.set('n', ']d', vim.diagnostic.goto_next, { desc = 'Go to next [D]iagnostic message' })
key.set('n', '<leader>e', vim.diagnostic.open_float, { desc = 'Show diagnostic [E]rror messages' })
key.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })

-- disable arrow keys in normal mode
key.set('', '<left>', '<cmd>echo "USE H TO MOVE!!"<CR>')
key.set('', '<right>', '<cmd>echo "USE L TO MOVE!!"<CR>')
key.set('', '<up>', '<cmd>echo "USE K TO MOVE!!"<CR>')
key.set('', '<down>', '<cmd>echo "USE J TO MOVE!!"<CR>')

-- oil file explorer
key.set('n', '<C-e>', '<CMD>Oil<CR>', { desc = '[E]xplore parent directory.' })

-- paste but persist whatever is in buffer
key.set('x', 'p', [["_dP]], { desc = '[P]aste and preserve buffer' })
