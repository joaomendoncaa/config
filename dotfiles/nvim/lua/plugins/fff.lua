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
        },
    },
}
