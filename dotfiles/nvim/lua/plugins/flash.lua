return {
    'folke/flash.nvim',

    event = 'VeryLazy',

    opts = {
        highlight = {
            backdrop = false,
        },
    },

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
