return {
    -- Multiple cursors plugin for vim/neovim.
    -- SEE: https://github.com/mg979/vim-visual-multi
    'mg979/vim-visual-multi',

    event = 'VeryLazy',

    init = function()
        local g = vim.g

        g.VM_silent_exit = 1
        g.VM_show_warnings = 0
    end,
}
