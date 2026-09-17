return {
    'mg979/vim-visual-multi',

    event = 'VeryLazy',

    init = function()
        local g = vim.g

        g.VM_silent_exit = 1
        g.VM_show_warnings = 0
        g.VM_maps = { ['Select All'] = '<leader>A', ['Visual All'] = '<leader>A' }
    end,
}
