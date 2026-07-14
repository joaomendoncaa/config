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

            local key = require('utils.misc').key

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
            key('n', '<leader>at', toggle, 'AI: Toggle inline suggestions')

            plugin.setup {
                keymaps = { clear_suggestion = '<C-c>' },
                log_level = 'off',
            }

            -- Monkey-patch log:warn/log:error to respect log_level (plugin bug:
            -- they bypass the level check and always call nvim_notify)
            local logger = require 'supermaven-nvim.logger'
            local config = require 'supermaven-nvim.config'
            local orig_warn = logger.warn
            local orig_error = logger.error
            logger.warn = function(self, msg)
                if config.config.log_level == 'off' then
                    return
                end
                orig_warn(self, msg)
            end
            logger.error = function(self, msg)
                if config.config.log_level == 'off' then
                    return
                end
                orig_error(self, msg)
            end

            -- Monkey-patch on_update to check buffer size cheaply (nvim_buf_get_offset
            -- is O(1)) before doing the expensive nvim_buf_get_lines + table.concat
            local binary = require 'supermaven-nvim.binary.binary_handler'
            local orig_on_update = binary.on_update
            binary.on_update = function(self, buffer, file_name, event_type)
                local line_count = vim.api.nvim_buf_line_count(buffer)
                local byte_size = line_count > 0 and vim.api.nvim_buf_get_offset(buffer, line_count) or 0
                if byte_size > self.HARD_SIZE_LIMIT then
                    return
                end
                return orig_on_update(self, buffer, file_name, event_type)
            end
        end,
    },
}
