return {
    -- SEE: https://github.com/echasnovski/mini.nvim
    'echasnovski/mini.nvim',

    config = function()
        local surround = require 'mini.surround'
        local move = require 'mini.move'
        local diff = require 'mini.diff'
        local jump2d = require 'mini.jump2d'
        local ai = require 'mini.ai'

        surround.setup {}

        move.setup {}

        diff.setup {}

        jump2d.setup {
            mappings = {
                start_jumping = '<CR>',
            },
            silent = true,
        }

        ai.setup {
            n_lines = 500,
        }
    end,
}
