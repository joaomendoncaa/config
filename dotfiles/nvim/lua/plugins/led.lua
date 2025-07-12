return {
    'joaomendoncaa/led.nvim',

    event = 'VeryLazy',

    config = function()
        local plugin = require 'led'

        plugin.setup {
            char = '●',
            ignore = { 'terminal', 'quickfix', 'nofile', 'codecompanion', 'NvimTree', 'noice' },
        }
    end,
}
