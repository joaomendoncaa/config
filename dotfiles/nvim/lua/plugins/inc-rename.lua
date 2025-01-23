return {
    'smjonas/inc-rename.nvim',

    event = 'VeryLazy',

    config = function()
        require('inc_rename').setup {
            preview_empty_name = true,
        }

        vim.keymap.set('n', '<leader>rn', ':IncRename ', { desc = '[R]e[n]ame.' })
    end,
}
