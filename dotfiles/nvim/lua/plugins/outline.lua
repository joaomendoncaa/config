return {
    -- Code outline sidebar powered by LSP. Significantly enhanced & refactored fork of symbols-outline.nvim.
    -- SEE: https://github.com/hedyhli/outline.nvim
    'hedyhli/outline.nvim',

    cmd = { 'Outline', 'OutlineOpen' },
    keys = {
        { '<leader>o', '<cmd>Outline<CR>', { desc = 'Toggle [O]utline.' } },
    },

    config = function()
        local plugin = require 'outline'

        local keymap = vim.keymap.set
        local autocmd = vim.api.nvim_create_autocmd

        keymap('n', '<leader>o', '<cmd>Outline<CR>', { desc = 'Toggle [O]utline.' })

        autocmd('BufEnter', {
            pattern = '*',
            callback = function()
                if vim.fn.winnr '$' == 1 and vim.bo.filetype == 'Outline' then
                    vim.cmd 'quit'
                end
            end,
        })

        plugin.setup {
            preview_window = {
                border = 'none',
            },
        }
    end,
}
