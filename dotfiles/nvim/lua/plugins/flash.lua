return {
    'folke/flash.nvim',

    event = 'VeryLazy',

    opts = {},

    keys = {
        {
            'S',
            mode = { 'n', 'x', 'o' },
            function()
                require('flash').jump()
            end,
            desc = 'Flash',
        },
    },
}
