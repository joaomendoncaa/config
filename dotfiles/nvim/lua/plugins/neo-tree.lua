return {
    'nvim-neo-tree/neo-tree.nvim',

    dependencies = {
        'nvim-lua/plenary.nvim',
        'MunifTanjim/nui.nvim',
        'nvim-tree/nvim-web-devicons',
    },

    cmd = 'Neotree',
    keys = {
        { '<leader>e', ':Neotree reveal<CR>', desc = 'NeoTree reveal', silent = true },
    },

    config = function()
        local plugin = require 'neo-tree'
        local snacks = require 'snacks'
        local commands = require 'utils.commands'
        local prev_file_name = { new_name = '', old_name = '' }

        local execute = require('neo-tree.command').execute

        local handle_close = function()
            execute { action = 'close' }
        end

        local subscribe_to_rename_event = function()
            local events = require('nvim-tree.api').events
            events.subscribe(events.Event.NodeRenamed, function(data)
                if prev_file_name.new_name ~= data.new_name or prev_file_name.old_name ~= data.old_name then
                    data = data
                    snacks.rename.on_rename_file(data.old_name, data.new_name)
                end
            end)
        end

        commands.auto('User', {
            pattern = 'NvimTreeSetup',
            callback = subscribe_to_rename_event,
        })

        plugin.setup {
            close_if_last_window = true,

            window = {
                mappings = {
                    ['P'] = { 'toggle_preview', config = { title = 'Preview' } },
                },
            },

            event_handlers = {
                {
                    event = 'file_opened',
                    handler = handle_close,
                },
            },

            filesystem = {
                filtered_items = {
                    hide_dotfiles = false,
                    hide_gitignored = false,
                    hide_hidden = false,
                },
                window = {
                    position = 'right',
                    mappings = {
                        ['h'] = 'close_node',
                        ['l'] = 'open',
                    },
                },
            },
        }
    end,
}
