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
            --- @module  'codecompanion'
            local plugin = require 'codecompanion'
            local commands = require 'utils.commands'

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

            local close_if_last_window = function()
                local current_win = vim.api.nvim_get_current_win()
                if vim.api.nvim_win_get_config(current_win).relative ~= '' then
                    return
                end

                local current_tab = vim.api.nvim_get_current_tabpage()
                local normal_windows = vim.tbl_filter(function(win)
                    return vim.api.nvim_win_get_config(win).relative == ''
                end, vim.api.nvim_tabpage_list_wins(current_tab))

                local window_count = #normal_windows
                if window_count ~= 1 and window_count ~= 2 then
                    return
                end

                local function get_window_filetypes(windows)
                    local types = {}
                    for _, win in ipairs(windows) do
                        local bufnr = vim.api.nvim_win_get_buf(win)
                        table.insert(types, vim.bo[bufnr].filetype)
                    end
                    return types
                end

                local filetypes = get_window_filetypes(normal_windows)

                local function should_close()
                    if window_count == 1 then
                        return filetypes[1] == 'codecompanion'
                    end

                    local has_companion = filetypes[1] == 'codecompanion' or filetypes[2] == 'codecompanion'
                    local has_neotree = filetypes[1] == 'neo-tree' or filetypes[2] == 'neo-tree'

                    return has_companion and has_neotree
                end

                if should_close() then
                    vim.cmd 'qa!'
                end
            end

            key({ 'n', 'v' }, '<leader>aa', toggle_chat_buffer, 'AI: Toggle chat buffer')
            key({ 'n', 'v' }, '<leader>al', ask_lsp_diagnostics, 'AI: Explain LSP diagnostics')
            key({ 'n', 'v' }, '<leader>ai', ask_inline, 'AI: Inline')
            key({ 'v' }, '<leader>ae', ask_explain_snippet, 'AI: Explain snippet')
            key({ 'v' }, '<leader>af', ask_fix_snippet, 'AI: Fix snippet')

            commands.auto('WinEnter', {
                group = commands.augroup 'CodeCompanionCloseIfLastWindow',
                callback = close_if_last_window,
            })

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
