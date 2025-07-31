return {
    'folke/noice.nvim',

    event = 'VeryLazy',
    dependencies = {
        'MunifTanjim/nui.nvim',
    },

    config = function()
        local plugin = require 'noice'
        local fidget = require 'fidget'
        local strings = require 'utils.strings'

        local greeter = strings.truncateChunks({
            { '󱐋', 'CursorLineNr' },
            { ' ' },
            { vim.fn.getcwd() },
            { ' ' },
            { string.format('~ %d ms', require('lazy').stats().startuptime), 'comment' },
        }, {
            length = vim.o.columns / 2,
            separator = '...',
            separator_hg = '@comment',
        })

        fidget.notify(
            table.concat(vim.tbl_map(function(chunk)
                return chunk[1]
            end, greeter)),
            nil,
            {}
        )

        -- plugin.setup {
        --     cmdline = {
        --         view = 'cmdline_popup',
        --         opts = {
        --             border = {
        --                 text = {
        --                     top = '',
        --                 },
        --             },
        --             position = {
        --                 row = 10,
        --             },
        --         },
        --     },
        -- }
    end,
}
