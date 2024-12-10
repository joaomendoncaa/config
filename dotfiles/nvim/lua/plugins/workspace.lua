return {
    {
        -- Neovim project manager, manage project within workspaces using Tmux sessions
        -- SEE: https://github.com/sanathks/workspace.nvim
        'sanathks/workspace.nvim',

        event = 'VeryLazy',
        dependencies = { 'nvim-telescope/telescope.nvim' },

        config = function()
            require('workspace').setup {
                workspaces = {
                    { name = 'Lab', path = '~/lab', keymap = { '<leader>sp' } },
                },
            }
        end,
    },
}
