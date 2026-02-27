return {
    {
        'dmtrKovalenko/fff.nvim',
        opts = {
            prompt = '> ',
            layout = { prompt_position = 'top', max_threads = 11, height = 0.7, width = 0.7 },
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
