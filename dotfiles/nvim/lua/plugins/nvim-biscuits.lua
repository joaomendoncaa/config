return {
    'code-biscuits/nvim-biscuits',

    event = 'VeryLazy',

    config = function()
        local plugin = require 'nvim-biscuits'

        plugin.setup {
            default_config = {
                min_distance = 15,
                prefix_string = '',
            },
            show_on_start = true,
        }
    end,
}
