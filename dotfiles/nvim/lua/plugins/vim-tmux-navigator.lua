return {
    -- Seamless navigation between tmux panes and vim splits.
    -- SEE: https://github.com/christoomey/vim-tmux-navigator
    'christoomey/vim-tmux-navigator',

    keys = {
        { '<c-h>', '<cmd><C-U>TmuxNavigateLeft<cr>' },
        { '<c-j>', '<cmd><C-U>TmuxNavigateDown<cr>' },
        { '<c-k>', '<cmd><C-U>TmuxNavigateUp<cr>' },
        { '<c-l>', '<cmd><C-U>TmuxNavigateRight<cr>' },
    },

    cmd = {
        'TmuxNavigateLeft',
        'TmuxNavigateDown',
        'TmuxNavigateUp',
        'TmuxNavigateRight',
        'TmuxNavigatePrevious',
    },
}
