return {
    {
        'olimorris/codecompanion.nvim',

        enabled = require('utils.flags').isTrue(vim.env.NVIM_AI),
        event = 'VeryLazy',

        dependencies = {
            'nvim-lua/plenary.nvim',
            'j-hui/fidget.nvim',
            'nvim-treesitter/nvim-treesitter',
            'saghen/blink.cmp',
        },

        config = function()
            local plugin = require 'codecompanion'
            local commands = require 'utils.commands'
            local progress = require 'fidget.progress'
            local f = require('utils.functions').f
            local key = require('utils.functions').key
            local progress_handle = nil

            local handle_request_cb = function(request)
                local is_request_started = request.match == 'CodeCompanionRequestStarted'
                local is_request_finished = request.match == 'CodeCompanionRequestFinished'

                if not is_request_started and not is_request_finished then
                    return
                end

                if not progress_handle then
                    progress_handle = nil
                end

                if is_request_started then
                    progress_handle = progress.handle.create {
                        title = '🤖',
                        message = "Gennin'",
                        lsp_client = { name = 'Anthropic' },
                    }
                    return
                end

                if is_request_finished then
                    if not progress_handle then
                        return
                    end

                    progress_handle:finish()
                    progress_handle = nil
                    return
                end
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

            local hide_chat_or_macro = function()
                if vim.bo.filetype ~= 'codecompanion' then
                    vim.api.nvim_feedkeys('q', 'n', false)
                    return
                end

                local chat = plugin.last_chat()

                if not chat then
                    return
                end

                if chat.ui:is_visible() then
                    return chat.ui:hide()
                end
            end

            key('n', 'q', hide_chat_or_macro, { desc = 'AI: Hide chat buffer, or record macro', noremap = true, silent = true })
            key({ 'n', 'v' }, '<leader>ai', ':CodeCompanion ', 'AI: Inline')
            key({ 'n', 'v' }, '<leader>aa', plugin.toggle, 'AI: Toggle chat buffer')
            key({ 'n', 'v' }, '<leader>aA', plugin.actions, 'AI: Actions')
            key({ 'n', 'v' }, '<leader>al', f(plugin.prompt, 'lsp'), 'AI: Explain LSP diagnostics')
            key({ 'v' }, '<leader>ad', f(plugin.prompt, 'docstrings'), 'AI: Add docstrings')
            key({ 'v' }, '<leader>ae', f(plugin.prompt, 'explain'), 'AI: Explain snippet')
            key({ 'v' }, '<leader>af', f(plugin.prompt, 'fix'), 'AI: Fix snippet')

            commands.auto('WinEnter', {
                group = commands.augroup 'CodeCompanionCloseIfLastWindow',
                callback = close_if_last_window,
            })

            commands.auto('User', {
                pattern = 'CodeCompanionRequest*',
                group = commands.augroup 'CodeCompanionHooks',
                callback = handle_request_cb,
            })

            plugin.setup {
                prompt_library = {
                    ['Generate Docstring'] = {
                        strategy = 'inline',
                        description = 'Add appropriate documentation to the selected code',
                        opts = {
                            short_name = 'docstrings',
                            auto_submit = true,
                        },
                        prompts = {
                            {
                                role = 'system',
                                content = function(context)
                                    return 'You are a senior '
                                        .. context.filetype
                                        .. ' developer. You add clear and appropriate documentation based on code context.'
                                end,
                            },
                            {
                                role = 'user',
                                content = function(context)
                                    local text = require('codecompanion.helpers.actions').get_code(context.start_line, context.end_line)
                                    return string.format(
                                        [[
Add appropriate documentation to this code:
- For functions: Add proper docstrings following language conventions, including types if present
- For configuration/script code: Add simple descriptive comments explaining purpose
- Do NOT modify any of the actual code - only add documentation
- Keep any existing documentation style
- Return the complete code with added documentation

```%s
%s
```]],
                                        context.filetype,
                                        text
                                    )
                                end,
                                opts = {
                                    contains_code = true,
                                },
                            },
                        },
                    },
                },
                strategies = {
                    chat = {
                        adapter = 'anthropic',
                        slash_commands = {
                            buffer = {
                                callback = 'strategies.chat.slash_commands.buffer',
                                description = 'Insert open buffers',
                                opts = { contains_code = true, provider = 'fzf_lua' },
                            },
                            file = { opts = { provider = 'fzf_lua' } },
                            help = { opts = { provider = 'fzf_lua' } },
                            symbols = { opts = { provider = 'fzf_lua' } },
                        },
                        keymaps = {
                            stop = {
                                modes = {
                                    n = 'c',
                                },
                                index = 5,
                                callback = 'keymaps.stop',
                                description = 'Stop Request',
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
                            env = { api_key = vim.env.ANTHROPIC_API_KEY },
                        })
                    end,
                },

                display = {
                    chat = {
                        intro_message = 'Press ? for options',
                    },
                },

                opts = {
                    log_level = 'INFO',
                },
            }
        end,
    },
}
