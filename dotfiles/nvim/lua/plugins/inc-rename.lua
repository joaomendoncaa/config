return {
    -- Incremental LSP renaming based on Neovim's command-preview feature.
    -- SEE: https://github.com/smjonas/inc-rename.nvim
    'smjonas/inc-rename.nvim',

    event = 'VeryLazy',

    config = function()
        require('inc_rename').setup {
            preview_empty_name = true,
        }

        vim.keymap.set('n', '<leader>rn', ':IncRename ', { desc = '[R]e[n]ame.' })
    end,
}
