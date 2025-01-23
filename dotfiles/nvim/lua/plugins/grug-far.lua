return {
    'MagicDuck/grug-far.nvim',

    event = 'VeryLazy',

    config = function()
        require('grug-far').setup {
            windowCreationCommand = 'tabnew %',
        }

        vim.keymap.set('n', '<leader>sr', '<CMD>GrugFar<CR>', { desc = '[S]earch [R]eplace.' })
    end,
}
