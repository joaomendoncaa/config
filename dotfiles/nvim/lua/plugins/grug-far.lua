return {
    -- Find And Replace plugin for neovim.
    -- SEE: https://github.com/MagicDuck/grug-far.nvim
    'MagicDuck/grug-far.nvim',

    event = 'VeryLazy',

    config = function()
        require('grug-far').setup {
            windowCreationCommand = 'tabnew',
        }

        vim.keymap.set('n', '<leader>sr', '<CMD>GrugFar<CR>', { desc = '[S]earch [R]eplace.' })
    end,
}
