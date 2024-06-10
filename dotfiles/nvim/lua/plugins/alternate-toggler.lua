return {
    -- A very small plugin for toggling alternate "boolean" values.
    -- SEE: https://github.com/rmagatti/alternate-toggler
    'rmagatti/alternate-toggler',

    keys = { '<leader><space>' },

    config = function()
        require('alternate-toggler').setup {
            alternates = {
                ['=='] = '!=',
            },
        }

        vim.keymap.set('n', '<leader><space>', "<cmd>lua require('alternate-toggler').toggleAlternate()<CR>", { desc = '[ ] Toggle Alternate.' })
    end,
}
