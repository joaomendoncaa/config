local SUFIX = 'leet'

return {
    'kawre/leetcode.nvim',

    lazy = SUFIX ~= vim.fn.argv(0),
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

        local key = require('utils.misc').key

        key('n', '<leader>Ll', '<CMD>Leet<CR>')
        key('n', '<leader>Lr', '<CMD>Leet run<CR>')
        key('n', '<leader>Ls', '<CMD>Leet submit<CR>')
        key('n', '<leader>Lb', '<CMD>Leet open<CR>')
        key('n', '<leader>Lh', '<CMD>CodeCompanion /dsa<CR>')

        plugin.setup {
            arg = SUFIX,
            lang = os.getenv 'LLANG' or 'typescript',
            picker = {
                provider = 'fzf-lua',
            },
            description = {
                width = '35%',
            },
        }
    end,
}
