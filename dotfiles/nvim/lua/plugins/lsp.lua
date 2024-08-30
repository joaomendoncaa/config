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

        commands.auto('LspAttach', {
            group = commands.augroup 'lsp-attach',

            callback = function(event)
                local builtin = require 'telescope.builtin'
                local client = vim.lsp.get_client_by_id(event.data.client_id)
                local buffer = event.buf

                local has_highlights = client and client.server_capabilities.documentHighlightProvider
                local has_inlay_hints = client and client.supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint)

                local keymap = vim.keymap.set

                local function toggle_inlay_hints()
                    vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled {})
                    print('Inlay hints ' .. (vim.lsp.inlay_hint.is_enabled {} and 'enabled' or 'disabled'))
                end

                keymap('n', 'gd', builtin.lsp_definitions, { desc = '[G]oto [D]efinition.' })
                keymap('n', 'gD', vim.lsp.buf.declaration, { desc = '[G]oto [D]eclaration' })
                keymap('n', 'gI', builtin.lsp_implementations, { desc = '[G]oto [I]mplementation.' })
                keymap('n', 'gr', builtin.lsp_references, { desc = '[G]oto [R]eferences.' })
                keymap('n', '<leader>D', builtin.lsp_type_definitions, { desc = 'Type [D]efinition.' })
                keymap('n', '<leader>ds', builtin.lsp_document_symbols, { desc = '[D]ocument [S]ymbols.' })
                keymap('n', '<leader>sw', builtin.lsp_dynamic_workspace_symbols, { desc = '[W]orkspace [S]ymbols.' })
                keymap({ 'n', 'v', 'x' }, '<leader>la', vim.lsp.buf.code_action, { desc = '[L]ist Code [A]ctions.' })

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
            end,
        })

        local capabilities = vim.tbl_deep_extend('force', vim.lsp.protocol.make_client_capabilities(), require('cmp_nvim_lsp').default_capabilities())

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

        require('mason').setup()

        require('mason-tool-installer').setup { ensure_installed = vim.tbl_keys(servers or {}) }

        require('mason-lspconfig').setup {
            handlers = {
                function(server_name)
                    local server = servers[server_name] or {}
                    -- INFO: This handles overriding only values explicitly passed
                    -- by the server configuration above. Useful when disabling
                    -- certain features of an LSP (for example, turning off formatting for tsserver)
                    server.capabilities = vim.tbl_deep_extend('force', {}, capabilities, server.capabilities or {})

                    require('lspconfig')[server_name].setup(server)
                end,
            },
        }
    end,
}
