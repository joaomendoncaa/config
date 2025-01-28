return {
    'rmagatti/alternate-toggler',

    keys = { '<leader><space>' },

    config = function()
        require('alternate-toggler').setup {
            alternates = {
                ['=='] = '!=',
                ['false'] = 'true',
                ['horizontal'] = 'vertical',
            },
        }

        vim.keymap.set('n', '<leader><space>', "<cmd>lua require('alternate-toggler').toggleAlternate()<CR>", { desc = '[ ] Toggle Alternate.' })
    end,
}
