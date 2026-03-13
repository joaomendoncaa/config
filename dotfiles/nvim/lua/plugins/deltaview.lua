return {
    {
        'kokusenz/deltaview.nvim',

        config = function()
            require('deltaview').setup {
                keyconfig = {
                    dv_toggle_keybind = '<leader>dd',
                },
                use_nerdfonts = true,
            }
        end,
    },
}
