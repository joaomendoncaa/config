return {
    'code-biscuits/nvim-biscuits',

    event = 'VeryLazy',

    config = function()
        local plugin = require 'nvim-biscuits'

        plugin.setup {
            show_on_start = true,
            default_config = {
                min_distance = 15,
                prefix_string = '',
            },
            language_config = {
                markdown = {
                    disabled = true,
                },
                codecompanion = {
                    disabled = true,
                },
            },
        }
    end,
}
