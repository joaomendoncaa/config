return {
    'neovim/nvim-lspconfig',

    event = 'VeryLazy',

    dependencies = {
        'williamboman/mason.nvim',
        'williamboman/mason-lspconfig.nvim',
        'WhoIsSethDaniel/mason-tool-installer.nvim',

        {
            'pmizio/typescript-tools.nvim',

            dependencies = {
                'nvim-lua/plenary.nvim',
                'neovim/nvim-lspconfig',
            },

            config = function()
                require('typescript-tools').setup {
                    settings = {
                        tsserver_file_preferences = {
                            includeInlayParameterNameHints = 'all',
                        },
                    },
                }
            end,
        },

        {
            'folke/lazydev.nvim',

            ft = 'lua',

            config = function()
                require('lazydev').setup {
                    library = {
                        -- Load luvit types when the `vim.uv` word is found
                        { path = 'luvit-meta/library', words = { 'vim%.uv' } },
                    },
                }
            end,
        },

        {
            'Bilal2453/luvit-meta',

            lazy = true,
        },

        {
            'j-hui/fidget.nvim',

            config = function()
                require('fidget').setup {
                    notification = {
                        window = { winblend = 0 },
                    },
                }
            end,
        },
    },

    config = function()
        local commands = require 'utils.commands'

        local servers = {
            gopls = {},
            rust_analyzer = {},
            tailwindcss = {},
            stylua = {},
            emmet_language_server = {},
            biome = {},
            lua_ls = {
                settings = {
                    Lua = {
                        completion = {
                            callSnippet = 'Replace',
                        },
                        diagnostics = { disable = { 'missing-fields' } },
                    },
                },
            },
        }

        local keymap = vim.keymap.set

        local function toggle_inlay_hints()
            vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled {})
            print('Inlay hints ' .. (vim.lsp.inlay_hint.is_enabled {} and 'enabled' or 'disabled'))
        end

        local function lsp_restart()
            vim.cmd 'LspRestart'
            vim.notify('LSP Restarting...', vim.log.levels.WARN)
        end

        local function lsp_start()
            vim.cmd 'LspStart'
            vim.notify('LSP Started.', vim.log.levels.INFO)
        end

        local function lsp_stop()
            vim.cmd 'LspStop'
            vim.notify('LSP Stopping...', vim.log.levels.OFF)
        end

        local function lsp_list()
            local clients = vim.lsp.get_clients()
            local current_buf = vim.api.nvim_get_current_buf()

            if #clients == 0 then
                vim.notify('No active LSP clients', vim.log.levels.INFO)
                return
            end

            local notif = 'Current buffer LSP clients\n\n'

            for i, client in ipairs(clients) do
                local status = client.attached_buffers[current_buf] and '|A|' or '|D|'
                local li = '- ' .. status .. ' ' .. client.name

                if i == #clients then
                    notif = notif .. li
                    break
                end

                notif = notif .. li .. '\n'
            end

            vim.notify(notif, vim.log.levels.INFO)
        end

        local function stop_lsp_by_name(opts)
            local input = opts.args and opts.args or ''
            local names = vim.split(input, '%s+', { trimempty = true })

            if #names == 0 then
                vim.notify('Please provide at least one client name', vim.log.levels.ERROR)
                return
            end

            local name_set = {}
            for _, name in ipairs(names) do
                name_set[name] = true
            end

            local clients = vim.lsp.get_clients()
            if #clients == 0 then
                vim.notify('No active LSP clients', vim.log.levels.ERROR)
                return
            end

            local stopped = {}
            local not_found = {}

            for _, client in ipairs(clients) do
                if name_set[client.name] then
                    vim.lsp.stop_client(client.id, true)
                    stopped[#stopped + 1] = client.name
                    name_set[client.name] = nil
                end
            end

            -- Collect names that weren't found
            for name, _ in pairs(name_set) do
                not_found[#not_found + 1] = name
            end

            if #stopped > 0 then
                print(string.format('Stopped LSP clients: %s', table.concat(stopped, ', ')))
            end

            if #not_found > 0 then
                vim.notify(string.format('LSP clients not found: %s', table.concat(not_found, ', ')), vim.log.levels.WARN)
            end
        end

        local function handle_mason_setup(server_name)
            local server = servers[server_name] or {}

            server.capabilities = vim.tbl_deep_extend('force', {
                textDocument = {
                    foldingRange = {
                        dynamicRegistration = false,
                        lineFoldingOnly = true,
                    },
                },
            }, vim.lsp.protocol.make_client_capabilities(), server.capabilities or {})

            require('lspconfig')[server_name].setup(server)
        end

        local function on_attach(event)
            local client = vim.lsp.get_client_by_id(event.data.client_id)
            local buffer = event.buf
            local has_highlights = client and client.server_capabilities.documentHighlightProvider
            local has_inlay_hints = client and client.supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint)

            keymap({ 'n', 'v', 'x' }, '<leader>la', vim.lsp.buf.code_action, { desc = '[L]sp code [A]ctions.' })
            keymap({ 'n', 'v', 'x' }, '<leader>lr', lsp_restart, { desc = '[L]sp [R]estart.' })
            keymap({ 'n', 'v', 'x' }, '<leader>lk', lsp_start, { desc = '[L]sp Start.' })
            keymap({ 'n', 'v', 'x' }, '<leader>lj', lsp_stop, { desc = '[L]sp Stop.' })
            keymap('n', '<leader>ll', lsp_list, { desc = '[L]sp [L]ist servers' })
            keymap('n', '<leader>la', vim.lsp.buf.code_action, { desc = '[L]sp code [A]ctions.' })

            if has_highlights then
                local highlight_augroup = commands.augroup('LspHighlight', { clear = false })

                commands.auto({ 'CursorHold', 'CursorHoldI' }, {
                    buffer = buffer,
                    group = highlight_augroup,
                    callback = vim.lsp.buf.document_highlight,
                })

                commands.auto({ 'CursorMoved', 'CursorMovedI' }, {
                    buffer = buffer,
                    group = highlight_augroup,
                    callback = vim.lsp.buf.clear_references,
                })

                commands.auto('LspDetach', {
                    group = commands.augroup('LspDetach', { clear = true }),
                    callback = function(event2)
                        vim.lsp.buf.clear_references()
                        vim.api.nvim_clear_autocmds { group = 'LspHighlight', buffer = event2.buf }
                    end,
                })
            end

            if has_inlay_hints then
                commands.user('ToggleInlayHints', toggle_inlay_hints)
            end
        end

        commands.auto('LspAttach', {
            group = commands.augroup 'LspAttach',
            callback = on_attach,
        })

        commands.user('ClientStop', stop_lsp_by_name, { nargs = '+' })

        require('mason').setup()
        require('mason-tool-installer').setup { ensure_installed = vim.tbl_keys(servers or {}) }
        require('mason-lspconfig').setup {
            handlers = { handle_mason_setup },
        }
    end,
}
