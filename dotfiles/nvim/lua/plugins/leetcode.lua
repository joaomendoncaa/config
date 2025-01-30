local SUFIX = 'leet'

return {
    'kawre/leetcode.nvim',

    lazy = SUFIX ~= vim.fn.argv(0, -1),
    build = ':TSUpdate html',
    cmd = 'Leet',

    dependencies = {
        'nvim-treesitter/nvim-treesitter',
        'ibhagwan/fzf-lua',
        'nvim-lua/plenary.nvim',
        'MunifTanjim/nui.nvim',
    },

    config = function()
        local plugin = require 'leetcode'

        plugin.setup {
            arg = SUFIX,
            lang = 'typescript',
            picker = {
                provider = 'fzf-lua',
            },
            description = {
                width = '20%',
            },
        }
    end,
}
