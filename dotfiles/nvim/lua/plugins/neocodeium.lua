return {
    {
        'monkoose/neocodeium',

        dependencies = {
            'saghen/blink.cmp',
        },
        event = 'VeryLazy',

        config = function()
            local plugin = require 'neocodeium'
            local blink = require 'blink.cmp'
            local key = require('utils.misc').key

            key({ 'n', 'i' }, '<A-.>', function()
                plugin.cycle_or_complete()
            end, 'NeoCodeium: next suggestion')

            key('i', '<A-y>', function()
                plugin.accept()
            end, 'NeoCodeium: accept suggestion')

            key('i', '<A-w>', function()
                plugin.accept_word()
            end, 'NeoCodeium: accept word')

            key('i', '<A-s>', function()
                plugin.accept_line()
            end, 'NeoCodeium: accept line')

            key('i', '<c-n>', function()
                plugin.cycle(1)
            end, 'NeoCodeium: next suggestion')

            key('i', '<c-p>', function()
                plugin.cycle(-1)
            end, 'NeoCodeium: previous suggestion')

            key('i', '<A-c>', function()
                plugin.clear()
            end, 'NeoCodeium: clear suggestion')

            vim.api.nvim_create_autocmd('User', {
                pattern = 'BlinkCmpMenuOpen',
                callback = function()
                    plugin.clear()
                end,
            })

            vim.api.nvim_create_autocmd('User', {
                pattern = 'NeoCodeiumCompletionDisplayed',
                callback = function()
                    blink.hide()
                end,
            })

            plugin.setup {
                manual = true,
                silent = true,
                filter = function()
                    return not blink.is_visible()
                end,
            }
        end,
    },
}
