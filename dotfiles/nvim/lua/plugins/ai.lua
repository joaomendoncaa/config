local key = function(mode, lhs, rhs, opts)
    local defaults = { silent = true, noremap = true }
    if type(opts) == 'string' then
        defaults.desc = opts
    end
    opts = type(opts) == 'table' and opts or {}
    vim.keymap.set(mode, lhs, rhs, vim.tbl_extend('force', defaults, opts))
end

return {
    {
        -- ✨ AI-powered coding, seamlessly in Neovim. Supports Anthropic, Copilot, Gemini, Ollama, OpenAI and xAI LLMs.
        -- SEE: https://github.com/olimorris/codecompanion.nvim
        'olimorris/codecompanion.nvim',

        enabled = require('utils.flags').isOne(vim.env.NVIM_AI),

        dependencies = {
            'nvim-lua/plenary.nvim',
            'nvim-treesitter/nvim-treesitter',
            'saghen/blink.cmp',
        },

        config = function()
            local plugin = require 'codecompanion'

            local toggle_chat_buffer = function()
                plugin.toggle()
            end

            local ask_inline = function()
                plugin.prompt 'inline'
            end

            local ask_lsp_diagnostics = function()
                plugin.prompt 'lsp'
            end

            local ask_explain_snippet = function()
                plugin.prompt 'explain'
            end

            local ask_fix_snippet = function()
                plugin.prompt 'fix'
            end

            key({ 'n', 'v' }, '<leader>aa', toggle_chat_buffer, 'AI: Toggle chat buffer')
            key({ 'n', 'v' }, '<leader>al', ask_lsp_diagnostics, 'AI: Explain LSP diagnostics')
            key({ 'n', 'v' }, '<leader>ai', ask_inline, 'AI: Inline')
            key({ 'v' }, '<leader>ae', ask_explain_snippet, 'AI: Explain snippet')
            key({ 'v' }, '<leader>af', ask_fix_snippet, 'AI: Fix snippet')

            plugin.setup {
                prompt_library = {
                    ['Custom Prompt'] = {
                        opts = {
                            short_name = 'inline',
                        },
                    },
                },
                strategies = {
                    chat = {
                        adapter = 'anthropic',
                        keymaps = {
                            hide = {
                                modes = {
                                    n = 'q',
                                },
                                callback = function(chat)
                                    chat.ui:hide()
                                end,
                                description = 'AI: Hide the chat buffer',
                            },
                        },
                    },
                    inline = {
                        adapter = 'anthropic',
                    },
                },
                adapters = {
                    anthropic = function()
                        return require('codecompanion.adapters').extend('anthropic', {
                            env = {
                                api_key = vim.env.ANTHROPIC_API_KEY,
                            },
                        })
                    end,
                },

                display = {
                    chat = {
                        intro_message = 'Press ? for options',
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
            local strings = require 'utils.strings'

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
                keymaps = {
                    clear_suggestion = '<C-c>',
                },
                log_level = 'off',
            }
        end,
    },
}
