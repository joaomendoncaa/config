return {
    {
        -- Use any external translate command/API in nvim.
        -- SEE: https://github.com/uga-rosa/translate.nvim
        'uga-rosa/translate.nvim',

        event = 'VeryLazy',

        config = function()
            require('translate').setup {}
        end,
    },
}
