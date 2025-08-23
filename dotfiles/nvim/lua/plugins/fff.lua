return {
    {
        'dmtrKovalenko/fff.nvim',
        build = 'cargo build --release',
        opts = {},
        keys = {
            {
                '<leader>PP',
                function()
                    require('fff').find_files()
                end,
                desc = 'Open file picker',
            },
        },
    },
}
