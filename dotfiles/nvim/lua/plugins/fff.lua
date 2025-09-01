return {
    {
        'dmtrKovalenko/fff.nvim',
        build = 'cargo build --release',
        opts = {
            prompt = '> ',
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
