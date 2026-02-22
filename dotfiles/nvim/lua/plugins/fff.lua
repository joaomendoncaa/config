return {
    {
        'dmtrKovalenko/fff.nvim',
        opts = {
            prompt = '> ',
            title = '',
            layout = { prompt_position = 'top' },
        },
        keys = {
            {
                '<leader>ss',
                function()
                    require('fff').find_files()
                end,
                desc = 'Open file picker',
            },
            {
                '<leader>sg',
                function()
                    require('fff').live_grep()
                end,
                desc = 'Open grep picker',
            },
        },
    },
}
