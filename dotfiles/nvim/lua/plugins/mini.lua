return {
    'echasnovski/mini.nvim',

    event = 'VeryLazy',

    config = function()
        local key = require('utils.functions').key
        local commands = require 'utils.commands'

        local function setup(mod, opts)
            opts = opts or {}
            require(string.format('mini.%s', mod)).setup(opts)
        end

        local indent_scope_on = function()
            setup('indentscope', {
                symbol = '│',
                draw = {
                    delay = 0,
                    animation = require('mini.indentscope').gen_animation.none(),
                },
                options = {
                    n_lines = 2000,
                },
            })
        end

        local indent_scope_off = function()
            setup('indentscope', { symbol = '' })
        end

        key('n', '<leader>ik', indent_scope_on, 'Toggle indent scope ON')
        key('n', '<leader>ij', indent_scope_off, 'Toggle indent scope OFF')

        commands.user('Trim', require('mini.trailspace').trim)

        setup 'surround'
        setup 'trailspace'
        setup 'pairs'
        setup 'move'
        setup 'diff'
        setup 'comment'
        setup 'cursorword'

        setup('ai', { n_lines = 1000 })

        setup('hipatterns', {
            highlighters = {
                fixme = { pattern = '%f[%w]()SEE()%f[%W]', group = 'MiniHipatternsFixme' },
                hack = { pattern = '%f[%w]()HACK()%f[%W]', group = 'MiniHipatternsHack' },
                todo = { pattern = '%f[%w]()TODO()%f[%W]', group = 'MiniHipatternsTodo' },
                note = { pattern = '%f[%w]()NOTE()%f[%W]', group = 'MiniHipatternsNote' },

                hex_color = require('mini.hipatterns').gen_highlighter.hex_color(),
            },
        })
    end,
}
