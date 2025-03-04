return {
    'JoosepAlviste/nvim-ts-context-commentstring',

    config = function()
        local plugin = require 'ts_context_commentstring'

        plugin.setup {
            enable_autocmd = false,
        }
    end,
}
