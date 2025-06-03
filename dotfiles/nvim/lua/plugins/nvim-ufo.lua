return {
    'kevinhwang91/nvim-ufo',

    event = 'VeryLazy',

    dependencies = {
        'kevinhwang91/promise-async',
    },

    config = function()
        local plugin = require 'ufo'

        local key = require('utils.misc').key

        key('n', 'zR', plugin.openAllFolds, 'Un[R]oll all folds.')
        key('n', 'zM', plugin.closeAllFolds, '[M]aster fold.')
        key('n', 'zz', 'za', { desc = 'Toggle fold', remap = true })

        plugin.setup {}
    end,
}
