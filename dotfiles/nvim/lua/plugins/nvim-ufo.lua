return {
    -- Not UFO in the sky, but an ultra fold in Neovim.
    -- SEE: https://github.com/kevinhwang91/nvim-ufo
    'kevinhwang91/nvim-ufo',

    event = 'VeryLazy',

    dependencies = {
        'kevinhwang91/promise-async',
    },

    config = function()
        local plugin = require 'ufo'

        local key = vim.keymap.set

        key('n', 'zR', plugin.openAllFolds, {
            desc = 'Un[R]oll all folds.',
        })
        key('n', 'zM', plugin.closeAllFolds, { desc = '[M]aster fold.' })
        key('n', 'zz', 'za', { desc = 'Toggle fold', remap = true })

        plugin.setup {}
    end,
}
