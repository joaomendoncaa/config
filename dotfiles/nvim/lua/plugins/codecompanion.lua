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
            local strings = require 'utils.strings'

            local f = require('utils.misc').func
            local key = require('utils.misc').key

            local slash_provider = 'telescope'
            local progress_handle = nil

            ---@param event 'started' | 'finished'
            local handle_stream_sfx = function(event)
                if event ~= 'started' and event ~= 'finished' then
                    return
                end

                local has_started = event == 'started'
                local path = vim.fn.stdpath 'config' .. '/media/' .. (has_started and 'notification-llm-started.wav' or 'notification-llm-finished.wav')

                vim.uv.spawn('paplay', {
                    args = { path },
                    detached = true,
                }, function() end)
            end

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
                    handle_stream_sfx 'started'
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

                    handle_stream_sfx 'finished'
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
            key({ 'n', 'v' }, '<C-a>', plugin.toggle, 'AI: Toggle chat buffer')
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
                            adapter = {
                                name = 'anthropic',
                                model = 'claude-3-5-haiku-latest',
                            },
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
                                        strings.dedent [[
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
                    ['Help with DSA exercise'] = {
                        strategy = 'chat',
                        description = 'Help with DSA exercises.',
                        opts = {
                            short_name = 'dsa',
                            auto_submit = false,
                            adapter = {
                                name = 'anthropic',
                                model = 'claude-3-5-haiku-latest',
                            },
                        },
                        prompts = {
                            {
                                role = 'system',
                                content = function(context)
                                    return 'You are a senior '
                                        .. context.filetype
                                        .. " developer and a wise teacher. You're the best person to help someone with DSA exercises."
                                end,
                            },
                            {
                                role = 'user',
                                content = function(context)
                                    local wins = vim.api.nvim_tabpage_list_wins(0)
                                    local win_l = vim.api.nvim_win_get_buf(wins[1])
                                    local win_r = vim.api.nvim_win_get_buf(wins[2])
                                    local lines_l = vim.api.nvim_buf_get_lines(win_l, 0, -1, false)
                                    local lines_r = vim.api.nvim_buf_get_lines(win_r, 0, -1, false)

                                    return string.format(
                                        strings.dedent [[
                                        *Critical: Help with this DSA exercise*
                                        - Do NOT give me any explicit solution
                                        - Give me hints on how to move forward depending on where I am in the implementation
                                        - Give me explanations of what I'm doing wrong if I'm not on the right track

                                        ## Problem
                                        ```md
                                        %s
                                        ```

                                        ## Current code
                                        ```%s
                                        %s
                                        ```
                                        ]],
                                        table.concat(lines_l, '\n'),
                                        context.filetype,
                                        table.concat(lines_r, '\n')
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
                            ['buffer'] = {
                                callback = 'strategies.chat.slash_commands.buffer',
                                description = 'Insert open buffers',
                                opts = { contains_code = true, provider = slash_provider },
                            },
                            ['file'] = { opts = { provider = slash_provider } },
                            ['help'] = { opts = { provider = slash_provider } },
                            ['symbols'] = { opts = { provider = slash_provider } },
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
                        window = {
                            width = 0.25,
                        },
                    },
                },

                opts = {
                    log_level = 'INFO',
                },
            }
        end,
    },
}
