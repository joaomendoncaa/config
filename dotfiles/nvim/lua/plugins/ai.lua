return {
    {
        -- The official Neovim plugin for Supermaven.
        -- SEE: https://github.com/supermaven-inc/supermaven-nvim
        'supermaven-inc/supermaven-nvim',

        event = 'VeryLazy',
        enabled = require('utils.flags').isOne(vim.env.NVIM_AI),

        config = function()
            local plugin = require 'supermaven-nvim'
            local api = require 'supermaven-nvim.api'
            local commands = require 'utils.commands'

            local function toggle()
                api.toggle()
                local status = api.is_running() and 'enabled' or 'disabled'
                print('AI suggestions are now ' .. status .. '.')
            end

            commands.user('ToggleAI', toggle)

            plugin.setup {
                keymaps = {
                    clear_suggestion = '<C-c>',
                },
                log_level = 'off',
            }
        end,
    },
}
