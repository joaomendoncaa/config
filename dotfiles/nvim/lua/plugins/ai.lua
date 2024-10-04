return {
    {
        -- Use your Neovim like using Cursor AI IDE!
        -- SEE: https://github.com/yetone/avante.nvim
        'yetone/avante.nvim',

        event = 'VeryLazy',
        version = false,
        build = 'make',
        enabled = require('utils.flags').isOne(vim.env.NVIM_AI),

        dependencies = {
            'nvim-treesitter/nvim-treesitter',
            'stevearc/dressing.nvim',
            'nvim-lua/plenary.nvim',
            'MunifTanjim/nui.nvim',
            'nvim-tree/nvim-web-devicons',

            {
                -- Support for image pasting.
                'HakonHarnes/img-clip.nvim',

                event = 'VeryLazy',

                config = function()
                    require('img-clip').setup {
                        default = {
                            embed_image_as_base64 = false,
                            prompt_for_file_name = false,
                            drag_and_drop = {
                                insert_mode = true,
                            },
                            use_absolute_path = true,
                        },
                    }
                end,
            },

            {
                -- Rendering Avante's markdown output.
                -- SEE: https://github.com/MeanderingProgrammer/render-markdown.nvim
                'MeanderingProgrammer/render-markdown.nvim',

                ft = { 'markdown', 'Avante' },

                config = function()
                    local plugin = require 'render-markdown'

                    plugin.setup {
                        file_types = { 'markdown', 'Avante' },
                    }
                end,
            },
        },

        config = function()
            local plugin = require 'avante'

            plugin.setup {
                claude = {
                    ['local'] = true,
                },
                provider = 'ollama',
                vendors = {
                    provider = 'ollama',
                    ---@type AvanteProvider
                    ollama = {
                        ['local'] = true,
                        endpoint = 'http://127.0.0.1:11434/v1',
                        model = 'codegemma',

                        parse_curl_args = function(opts, code_opts)
                            return {
                                url = opts.endpoint .. '/chat/completions',
                                headers = {
                                    ['Accept'] = 'application/json',
                                    ['Content-Type'] = 'application/json',
                                },
                                body = {
                                    model = opts.model,
                                    messages = require('avante.providers').copilot.parse_message(code_opts),
                                    max_tokens = 2048,
                                    stream = true,
                                },
                            }
                        end,

                        parse_response_data = function(data_stream, event_state, opts)
                            require('avante.providers').openai.parse_response(data_stream, event_state, opts)
                        end,
                    },
                },
            }
        end,
    },
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
