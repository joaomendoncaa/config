return {
    -- SEE: https://github.com/echasnovski/mini.nvim
    'echasnovski/mini.nvim',

    config = function()
        local ai = require 'mini.ai'
        local surround = require 'mini.surround'
        local move = require 'mini.move'
        local jump2d = require 'mini.jump2d'
        local diff = require 'mini.diff'

        surround.setup {}

        move.setup {}

        diff.setup {}

        ai.setup { n_lines = 500 }

        jump2d.setup {
            mappings = {
                start_jumping = '<CR>',
            },
            silent = true,
        }
    end,
}
