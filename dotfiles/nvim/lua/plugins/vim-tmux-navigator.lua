return {
    -- Seamless navigation between tmux panes and vim splits.
    -- SEE: https://github.com/christoomey/vim-tmux-navigator
    'christoomey/vim-tmux-navigator',

    lazy = 'true',
    cmd = {
        'TmuxNavigateLeft',
        'TmuxNavigateDown',
        'TmuxNavigateUp',
        'TmuxNavigateRight',
        'TmuxNavigatePrevious',
    },

    config = function()
        local keymap = vim.keymap.set

        keymap('n', '<c-h>', '<cmd><C-U>TmuxNavigateLeft<cr>', { desc = 'Tmux Navigate Left.' })
        keymap('n', '<c-j>', '<cmd><C-U>TmuxNavigateDown<cr>', { desc = 'Tmux Navigate Down.' })
        keymap('n', '<c-k>', '<cmd><C-U>TmuxNavigateUp<cr>', { desc = 'Tmux Navigate Up.' })
        keymap('n', '<c-l>', '<cmd><C-U>TmuxNavigateRight<cr>', { desc = 'Tmux Navigate Right.' })
    end,
}
