return {
    {
        'dmtrKovalenko/fff.nvim',
        build = function()
            require('fff.download').download_or_build_binary()
        end,
        opts = {
            prompt = '> ',
            layout = { prompt_position = 'top', max_threads = 11, height = 0.7, width = 0.7 },
            keymaps = { select_vsplit = '<C-x>' },
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
