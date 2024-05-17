return {
    -- Search based navigation combined with quick jump features.
    -- SEE: https://github.com/woosaaahh/sj.nvim
    'woosaaahh/sj.nvim',

    event = 'VeryLazy',

    config = function()
        local sj = require 'sj'

        sj.setup()

        vim.keymap.set('n', 'S', function()
            sj.run {
                auto_jump = false,
                stop_on_fail = false,
                separator = ':',
            }
        end, { desc = 'Jump to [S]earch pattern.' })
    end,
}
