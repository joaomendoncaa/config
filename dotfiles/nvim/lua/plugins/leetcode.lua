return {
    'kawre/leetcode.nvim',

    build = ':TSUpdate html',

    depeendencies = {
        'nvim-treesitter/nvim-treesitter',
        'ibhagwan/fzf-lua',
        'nvim-lua/plenary.nvim',
        'MunifTanjim/nui.nvim',
    },

    config = function()
        local plugin = require 'leetcode'

        plugin.setup {
            lang = 'typescript',
            picker = {
                provider = 'fzf-lua',
            },
        }
    end,
}
