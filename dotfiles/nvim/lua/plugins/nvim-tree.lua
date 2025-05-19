return {
    'nvim-tree/nvim-tree.lua',

    event = 'VeryLazy',
    dependencies = {
        'nvim-tree/nvim-web-devicons',
    },

    config = function()
        local plugin = require 'nvim-tree'
        local api = require 'nvim-tree.api'

        local key = require('utils.functions').key

        local handle_attach = function(bufnr)
            api.config.mappings.default_on_attach(bufnr)

            key('n', 'h', api.node.navigate.parent_close, { buffer = bufnr, desc = 'Close directory' })
            key('n', 'l', api.node.open.edit, { buffer = bufnr, desc = 'Open file/directory' })
            key('n', 'q', api.tree.close, { buffer = bufnr, desc = 'Close tree' })
        end

        key('n', '<leader>ee', '<CMD>NvimTreeToggle<CR>', 'Toggle [E]xplorer')

        plugin.setup {
            view = {
                side = 'right',
                width = 35,
            },
            on_attach = handle_attach,
        }
    end,
}
