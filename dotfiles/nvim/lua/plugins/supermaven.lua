return {
    {
        'supermaven-inc/supermaven-nvim',

        event = 'VeryLazy',
        enabled = require('utils.flags').isTrue(vim.env.NVIM_AI),

        config = function()
            local plugin = require 'supermaven-nvim'
            local api = require 'supermaven-nvim.api'
            local commands = require 'utils.commands'
            local strings = require 'utils.strings'

            local key = vim.keymap.set

            local function toggle()
                local is_on = api.is_running()

                api.toggle()

                vim.api.nvim_set_hl(0, 'T', { fg = is_on and '#ff0000' or '#00ff00' })

                strings.echo(strings.truncateChunks {
                    { is_on and '[OFF]' or '[ON]', 'T' },
                    { ' ' },
                    { 'AI suggestions' },
                })
            end

            commands.user('ToggleAISuggestions', toggle)
            key('n', '<leader>at', toggle, { desc = 'AI: Toggle inline suggestions' })

            plugin.setup {
                keymaps = { clear_suggestion = '<C-c>' },
                log_level = 'off',
            }
        end,
    },
}
