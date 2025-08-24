return {
    'chrisgrieser/nvim-origami',

    event = 'VeryLazy',
    opts = {
        foldtext = {
            lineCount = {
                template = ' %d',
            },
        },
    },

    init = function()
        local folds = require 'utils.folds'
        local commands = require 'utils.commands'
        local key = require('utils.misc').key

        key('n', 'zz', 'za', { noremap = true, silent = true })
        key('n', 'zr', 'zR', { noremap = true, silent = true })

        commands.auto({ 'TextChanged', 'InsertLeave', 'LspAttach' }, {
            callback = function(opts)
                folds.update_ranges(opts.buf)
            end,
        })

        commands.auto('CursorMoved', {
            callback = function(opts)
                folds.handle_cursor_update(opts)
            end,
        })

        commands.auto({ 'BufUnload', 'BufWipeout' }, {
            callback = function(opts)
                folds.clear(opts.buf)
            end,
        })

        vim.o.statuscolumn = '%!v:lua.StatusCol()'

        function _G.StatusCol()
            return folds.statuscol()
        end
    end,
}
