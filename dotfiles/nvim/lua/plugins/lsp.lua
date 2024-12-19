return {
    -- Quickstart configs for Nvim LSP.
    -- SEE: https://github.com/neovim/nvim-lspconfig
    'neovim/nvim-lspconfig',

    dependencies = {
        {
            -- Portable package manager for Neovim that runs everywhere Neovim runs. Easily install and manage LSP servers, DAP servers, linters, and formatters.
            -- SEE: https://github.com/williamboman/mason.nvim
            'williamboman/mason.nvim',
        },

        {
            -- Extension to mason.nvim that makes it easier to use lspconfig with mason.nvim.
            -- SEE: https://github.com/williamboman/mason-lspconfig.nvim
            'williamboman/mason-lspconfig.nvim',
        },

        {
            -- Install and upgrade third party tools automatically.
            -- SEE: https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim
            'WhoIsSethDaniel/mason-tool-installer.nvim',
        },

        {
            -- TypeScript integration NeoVim deserves.
            -- SEE: https://github.com/pmizio/typescript-tools.nvim
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
            -- Faster LuaLS setup for Neovim.
            -- SEE: https://github.com/folke/lazydev.nvim
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
            -- Meta type definitions for the Lua platform Luvit.
            -- SEE: https://github.com/Bilal2453/luvit-meta
            'Bilal2453/luvit-meta',

            lazy = true,
        },

        {
            -- Extensible UI for Neovim notifications and LSP progress messages.
            -- SEE: https://github.com/j-hui/fidget.nvim
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
        -- @module fzf-lua
        local fzf = require 'fzf-lua'

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

        local function lsp_restart()
            vim.cmd 'LspRestart'
            print 'LSP Restarting'
        end

        local function lsp_start()
            vim.cmd 'LspStart'
            print 'LSP Started'
        end

        local function lsp_stop()
            vim.cmd 'LspStop'
            print 'LSP Stopped'
        end

        local function toggle_inlay_hints()
            vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled {})
            print('Inlay hints ' .. (vim.lsp.inlay_hint.is_enabled {} and 'enabled' or 'disabled'))
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

        local function list_lsps()
            local clients = vim.lsp.get_clients()

            if #clients == 0 then
                print 'No active LSP clients'
                return
            end

            local notif = 'Active clients: {'

            for i, client in ipairs(clients) do
                if i == #clients then
                    notif = notif .. client.name
                else
                    notif = notif .. client.name .. ', '
                end
            end

            vim.notify(notif, vim.log.levels.INFO)
        end

        local function handle_mason_setup(server_name)
            local server = servers[server_name] or {}
            -- INFO: This handles overriding only values explicitly passed
            -- by the server configuration above. Useful when disabling
            -- certain features of an LSP (for example, turning off formatting for tsserver)
            server.capabilities = vim.tbl_deep_extend('force', {}, vim.lsp.protocol.make_client_capabilities(), server.capabilities or {})

            require('lspconfig')[server_name].setup(server)
        end

        local function on_attach(event)
            local client = vim.lsp.get_client_by_id(event.data.client_id)
            local buffer = event.buf
            local has_highlights = client and client.server_capabilities.documentHighlightProvider
            local has_inlay_hints = client and client.supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint)

            keymap('n', 'gd', fzf.lsp_definitions, { desc = '[G]oto [D]efinition.' })
            keymap('n', 'gD', vim.lsp.buf.declaration, { desc = '[G]oto [D]eclaration' })
            keymap('n', 'gI', fzf.lsp_implementations, { desc = '[G]oto [I]mplementation.' })
            keymap('n', 'gr', fzf.lsp_references, { desc = '[G]oto [R]eferences.' })
            keymap('n', '<leader>D', fzf.lsp_typedefs, { desc = 'Type [D]efinition.' })
            keymap('n', '<leader>ds', fzf.lsp_document_symbols, { desc = '[D]ocument [S]ymbols.' })
            keymap('n', '<leader>sw', fzf.lsp_workspace_symbols, { desc = '[W]orkspace [S]ymbols.' })
            keymap({ 'n', 'v', 'x' }, '<leader>la', vim.lsp.buf.code_action, { desc = '[L]sp code [A]ctions.' })
            keymap({ 'n', 'v', 'x' }, '<leader>lr', lsp_restart, { desc = '[L]sp [R]estart.' })
            keymap({ 'n', 'v', 'x' }, '<leader>lk', lsp_start, { desc = '[L]sp Start.' })
            keymap({ 'n', 'v', 'x' }, '<leader>lj', lsp_stop, { desc = '[L]sp Stop.' })
            keymap('n', '<leader>ll', list_lsps, { desc = '[L]sp [L]ist servers' })

            if has_highlights then
                local highlight_augroup = commands.augroup('lsp-highlight', { clear = false })

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
                    group = commands.augroup('lsp-detach', { clear = true }),
                    callback = function(event2)
                        vim.lsp.buf.clear_references()
                        vim.api.nvim_clear_autocmds { group = 'lsp-highlight', buffer = event2.buf }
                    end,
                })
            end

            if has_inlay_hints then
                commands.user('ToggleInlayHints', toggle_inlay_hints)
            end
        end

        commands.auto('LspAttach', {
            group = commands.augroup 'lsp-attach',
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
