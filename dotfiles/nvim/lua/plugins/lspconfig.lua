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
                require('lazydev').setup {}
            end,
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
        vim.api.nvim_create_autocmd('LspAttach', {
            group = vim.api.nvim_create_augroup('lsp-attach', { clear = true }),

            callback = function(event)
                local builtin = require 'telescope.builtin'

                local keymap = vim.keymap.set

                keymap('n', 'gd', builtin.lsp_definitions, { desc = '[G]oto [D]efinition.' })
                keymap('n', 'gD', vim.lsp.buf.declaration, { desc = '[G]oto [D]eclaration' })
                keymap('n', 'gI', builtin.lsp_implementations, { desc = '[G]oto [I]mplementation.' })
                keymap('n', 'gr', builtin.lsp_references, { desc = '[G]oto [R]eferences.' })
                keymap('n', '<leader>D', builtin.lsp_type_definitions, { desc = 'Type [D]efinition.' })
                keymap('n', '<leader>ds', builtin.lsp_document_symbols, { desc = '[D]ocument [S]ymbols.' })
                keymap('n', '<leader>sw', builtin.lsp_dynamic_workspace_symbols, { desc = '[W]orkspace [S]ymbols.' })
                keymap({ 'n', 'v' }, '<leader>la', vim.lsp.buf.code_action, { desc = '[L]ist Code [A]ctions.' })

                local client = vim.lsp.get_client_by_id(event.data.client_id)
                if client and client.server_capabilities.documentHighlightProvider then
                    -- INFO: The following autocommands are used to highlight references of the
                    -- word under your cursor when your cursor rests there for a little while.
                    -- SEE: `:help CursorHold` for information about when this is executed
                    --
                    -- When you move your cursor, the highlights will be cleared (the second autocommand).
                    local highlight_augroup = vim.api.nvim_create_augroup('lsp-highlight', { clear = false })
                    vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
                        buffer = event.buf,
                        group = highlight_augroup,
                        callback = vim.lsp.buf.document_highlight,
                    })

                    vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
                        buffer = event.buf,
                        group = highlight_augroup,
                        callback = vim.lsp.buf.clear_references,
                    })

                    vim.api.nvim_create_autocmd('LspDetach', {
                        group = vim.api.nvim_create_augroup('lsp-detach', { clear = true }),
                        callback = function(event2)
                            vim.lsp.buf.clear_references()
                            vim.api.nvim_clear_autocmds { group = 'lsp-highlight', buffer = event2.buf }
                        end,
                    })
                end

                -- if lsp supports it, toggle inlay hints
                if client and client.server_capabilities.inlayHintProvider and vim.lsp.inlay_hint then
                    keymap('n', '<leader>th', function()
                        vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled {})
                        print('Inlay hints ' .. (vim.lsp.inlay_hint.is_enabled {} and 'enabled' or 'disabled'))
                    end, { desc = '[T]oggle Inlay [H]ints.' })
                end
            end,
        })

        local capabilities = vim.lsp.protocol.make_client_capabilities()
        capabilities = vim.tbl_deep_extend('force', capabilities, require('cmp_nvim_lsp').default_capabilities())

        local servers = {
            gopls = {},
            rust_analyzer = {},
            tailwindcss = {},
            stylua = {},
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
