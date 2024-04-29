local key = vim.keymap

key.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- Diagnostic keymaps
key.set('n', '[d', vim.diagnostic.goto_prev, { desc = 'Go to previous [D]iagnostic message' })
key.set('n', ']d', vim.diagnostic.goto_next, { desc = 'Go to next [D]iagnostic message' })
key.set('n', '<leader>e', vim.diagnostic.open_float, { desc = 'Show diagnostic [E]rror messages' })
key.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })

-- Exit terminal mode in the builtin terminal with a shortcut that is a bit easier
-- for people to discover. Otherwise, you normally need to press <C-\><C-n>, which
-- is not what someone will guess without a bit more experience.
--
-- NOTE: This won't work in all terminal emulators/tmux/etc. Try your own mapping
-- or just use <C-\><C-n> to exit terminal mode
key.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- Disable arrow keys in normal mode
key.set('', '<left>', '<cmd>echo "USE H TO MOVE!!"<CR>')
key.set('', '<right>', '<cmd>echo "USE L TO MOVE!!"<CR>')
key.set('', '<up>', '<cmd>echo "USE K TO MOVE!!"<CR>')
key.set('', '<down>', '<cmd>echo "USE J TO MOVE!!"<CR>')

-- Oil.nvim
key.set('n', '<C-e>', '<CMD>Oil<CR>', { desc = '[E]xplore parent directory.' })

-- paste but persist whatever is in buffer
key.set('x', 'p', [["_dP]], { desc = '[P]aste and preserve buffer' })

-- Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.highlight.on_yank()`
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})
