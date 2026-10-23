return {
    {
        'kokusenz/deltaview.nvim',

        config = function()
            local plugin = require 'deltaview'
            local view = require 'deltaview.view'
            local file = view.deltaview_file

            view.deltaview_file = function(...)
                if vim.b.delta_diff_data_set ~= nil then
                    vim.cmd 'bdelete'
                    return
                end
                return file(...)
            end

            plugin.setup {
                keyconfig = {
                    dv_toggle_keybind = '<leader>dd',
                },
                use_nerdfonts = true,
            }
        end,
    },
}
