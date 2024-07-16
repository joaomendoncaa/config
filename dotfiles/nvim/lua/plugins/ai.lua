return {
    {
        -- The official Neovim plugin for Supermaven.
        -- SEE: https://github.com/supermaven-inc/supermaven-nvim
        'supermaven-inc/supermaven-nvim',

        event = 'VeryLazy',
        enabled = require('utils.flags').isOne(vim.env.NVIM_AI),

        config = function()
            local plugin = require 'supermaven-nvim'
            local plugin_api = require 'supermaven-nvim.api'

            local toggle = function()
                plugin_api.toggle()

                local status = plugin_api.is_running() and 'enabled' or 'disabled'

                print('AI suggestions are now ' .. status .. '.')
            end

            vim.api.nvim_create_user_command('ToggleAI', toggle, {})

            plugin.setup {
                keymaps = {
                    accept_suggestion = '<C-y>',
                    clear_suggestion = '<C-c>',
                },
                log_level = 'off',
            }
        end,
    },
}
