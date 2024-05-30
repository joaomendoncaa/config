return {
    {
        -- The official Neovim plugin for Supermaven.
        -- SEE: https://github.com/supermaven-inc/supermaven-nvim
        'supermaven-inc/supermaven-nvim',

        event = 'VeryLazy',
        enabled = require('utils.flags').isOne(vim.env.AI),

        config = function()
            require('supermaven-nvim').setup {
                keymaps = {
                    accept_suggestion = '<C-y>',
                    clear_suggestion = '<C-c>',
                    accept_word = '<C-Y>',
                },
            }
        end,
    },
}
