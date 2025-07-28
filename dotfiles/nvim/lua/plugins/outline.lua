return {
    'hedyhli/outline.nvim',

    cmd = { 'Outline', 'OutlineOpen' },
    keys = {
        { '<leader>O' },
    },

    config = function()
        local plugin = require 'outline'

        local key = require('utils.misc').key
        local autocmd = vim.api.nvim_create_autocmd

        key('n', '<leader>o', '<cmd>OutlineOpen<CR>', 'Toggle [O]utline.')

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
