return {
    {
        'mbbill/undotree',

        event = 'VeryLazy',

        config = function()
            local key = require('utils.misc').key

            vim.g.undotree_WindowLayout = 3

            local handle_toggle = function()
                local current_buf = vim.api.nvim_get_current_buf()
                local current_ft = string.lower(vim.bo[current_buf].filetype or '')
                if vim.tbl_contains({ 'codecompanion', 'nvimtree' }, current_ft) then
                    return
                end
                vim.cmd 'UndotreeToggle'
            end

            key('n', '<c-t>', handle_toggle, 'Toggle Undo[T]ree')
        end,
    },
}
